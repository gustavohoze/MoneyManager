#!/usr/bin/env python3
"""
Parse bank-statement-like PDFs into transaction JSON.

Usage:
  .venv/bin/python tools/pdf_statement_parser.py /path/to/statement.pdf
  .venv/bin/python tools/pdf_statement_parser.py /path/to/statement.pdf --pretty
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path
from typing import Iterable, List, Optional

from pypdf import PdfReader


AMOUNT_RE = re.compile(
    r"(?:Rp\.?|IDR|USD|\$)?\s*([+-]?\d+(?:[.,]\d{3})*(?:[.,]\d{1,2})?)",
    re.IGNORECASE,
)

DATE_PATTERNS = [
    "%d/%m/%Y",
    "%d-%m-%Y",
    "%Y-%m-%d",
    "%d %b %Y",
    "%d %B %Y",
    "%b %d, %Y",
    "%B %d, %Y",
    "%d %b",
    "%d %B",
]

DATE_TOKEN_RE = re.compile(
    r"\b\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?\b"
    r"|\b\d{1,2}\s+[A-Za-z]{3,9}(?:\s+\d{2,4})?\b"
)

BALANCE_KEYWORDS = (
    "balance",
    "available balance",
    "ending balance",
    "saldo",
    "saldo akhir",
)

SKIP_KEYWORDS = (
    "balance",
    "account",
    "transfer",
    "date",
    "time",
    "debit",
    "credit",
    "saldo",
)


@dataclass
class ParsedTransaction:
    merchantRaw: str
    amount: float
    date: str
    isIncome: bool


def normalize_amount(raw: str) -> Optional[float]:
    text = raw.strip()
    if not text:
        return None

    sign = -1 if text.startswith("-") else 1
    value = text.replace("+", "").replace("-", "")

    last_dot = value.rfind(".")
    last_comma = value.rfind(",")

    if last_dot >= 0 and last_comma >= 0:
        if last_dot > last_comma:
            value = value.replace(",", "")
        else:
            value = value.replace(".", "")
            value = value[::-1].replace(",", ".", 1)[::-1]
    elif last_comma >= 0:
        decimals = len(value) - last_comma - 1
        if decimals == 2:
            value = value[::-1].replace(",", ".", 1)[::-1]
        else:
            value = value.replace(",", "")
    else:
        parts = value.split(".")
        if len(parts) > 1 and len(parts[-1]) == 2:
            value = "".join(parts[:-1]) + "." + parts[-1]
        else:
            value = value.replace(".", "")

    try:
        parsed = float(value)
    except ValueError:
        return None
    return sign * parsed


def detect_date(text: str, current_year: int) -> Optional[datetime]:
    match = DATE_TOKEN_RE.search(text)
    if not match:
        return None

    token = match.group(0).strip()
    for pattern in DATE_PATTERNS:
        try:
            dt = datetime.strptime(token, pattern)
            if "%Y" not in pattern:
                dt = dt.replace(year=current_year)
            return dt
        except ValueError:
            continue
    return None


def extract_text_lines(pdf_path: Path) -> List[str]:
    reader = PdfReader(str(pdf_path))
    lines: List[str] = []
    for page in reader.pages:
        text = page.extract_text() or ""
        for line in text.splitlines():
            clean = line.strip()
            if clean:
                lines.append(clean)
    return lines


def infer_income(line_lower: str, amount: float) -> bool:
    if " cr" in line_lower or "credit" in line_lower or "masuk" in line_lower:
        return True
    if " dr" in line_lower or "debit" in line_lower or "keluar" in line_lower:
        return False
    return amount > 0 and "+" in line_lower


def extract_merchant(line: str) -> Optional[str]:
    cleaned = AMOUNT_RE.sub(" ", line)
    cleaned = DATE_TOKEN_RE.sub(" ", cleaned)
    cleaned = re.sub(r"\s+", " ", cleaned).strip()

    lower = cleaned.lower()
    if any(keyword in lower for keyword in SKIP_KEYWORDS):
        return None
    if not any(ch.isalpha() for ch in cleaned):
        return None
    if not (2 < len(cleaned) < 90):
        return None
    return cleaned


def parse_transactions(lines: Iterable[str]) -> List[ParsedTransaction]:
    now = datetime.now()
    current_date: Optional[datetime] = None
    parsed: List[ParsedTransaction] = []

    lines_list = list(lines)
    for idx, line in enumerate(lines_list):
        lower = line.lower()

        detected = detect_date(line, now.year)
        if detected is not None:
            current_date = detected

        if any(keyword in lower for keyword in BALANCE_KEYWORDS):
            continue

        candidates = [
            normalize_amount(m.group(1))
            for m in AMOUNT_RE.finditer(line)
        ]
        candidates = [c for c in candidates if c is not None and abs(c) > 0]
        if not candidates:
            continue

        amount = min(candidates, key=lambda x: abs(x))

        merchant = extract_merchant(line)
        if merchant is None:
            for neighbor in (idx - 1, idx + 1):
                if 0 <= neighbor < len(lines_list):
                    neighbor_line = lines_list[neighbor]
                    if not AMOUNT_RE.search(neighbor_line):
                        merchant = extract_merchant(neighbor_line)
                        if merchant:
                            break

        parsed.append(
            ParsedTransaction(
                merchantRaw=merchant or "Unknown Merchant",
                amount=abs(float(amount)),
                date=(current_date or now).date().isoformat(),
                isIncome=infer_income(lower, float(amount)),
            )
        )

    deduped: List[ParsedTransaction] = []
    seen = set()
    for tx in parsed:
        key = (tx.merchantRaw.lower(), int(round(tx.amount)), tx.date, tx.isIncome)
        if key in seen:
            continue
        seen.add(key)
        deduped.append(tx)
    return deduped


def main() -> int:
    parser = argparse.ArgumentParser(description="Parse bank statement PDF into JSON transactions")
    parser.add_argument("pdf", type=Path, help="Path to PDF statement")
    parser.add_argument("--pretty", action="store_true", help="Pretty JSON output")
    args = parser.parse_args()

    if not args.pdf.exists():
        raise SystemExit(f"File not found: {args.pdf}")

    lines = extract_text_lines(args.pdf)
    transactions = parse_transactions(lines)

    payload = [asdict(tx) for tx in transactions]
    if args.pretty:
        print(json.dumps(payload, indent=2, ensure_ascii=True))
    else:
        print(json.dumps(payload, ensure_ascii=True))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
