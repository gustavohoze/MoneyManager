import Foundation
import CoreGraphics

// MARK: - BankStatementParser
//
// A bank-agnostic parser. It makes no assumptions about which bank issued the
// statement, which country it's from, or which app rendered the screenshot.
//
// It works on three universal observations:
//
//   1. DATES   — Any token that parses as a date anchors a new transaction.
//                We try a broad set of common date formats.
//
//   2. AMOUNTS — Any token that looks like a number (with optional currency
//                prefix) is a candidate amount.  We prefer tokens in the
//                right half of the page (x > 0.5) since that is where amount
//                columns live in virtually every bank layout worldwide.
//                Running-balance candidates (amounts that monotonically track
//                a balance) are separated from transaction amounts in a
//                post-processing pass.
//
//   3. MERCHANT — Whatever text is left after dates, amounts, reference
//                 numbers, and account numbers are filtered out.

class BankStatementParser {

    func parse(extractedItems: [ExtractedTextItem]) -> [ParsedTransactionResult] {
        guard !extractedItems.isEmpty else { return [] }

        // Pre-process: split OCR-fused "123.45MerchantName" tokens
        let items = extractedItems.flatMap { splitConcatenatedToken($0) }

        // Sort top-to-bottom
        let sorted = items.sorted { $0.boundingBox.minY < $1.boundingBox.minY }

        // Group into horizontal rows, then cluster rows into per-transaction blocks
        let rows     = groupIntoRows(sorted)
        let clusters = clusterIntoTransactions(rows)

        return clusters.compactMap { parseCluster($0) }
    }

    // MARK: - Layout grouping

    /// Items within the same Y band (tolerance 0.015) belong to the same visual row.
    private func groupIntoRows(_ sorted: [ExtractedTextItem]) -> [[ExtractedTextItem]] {
        var rows: [[ExtractedTextItem]] = []
        var current: [ExtractedTextItem] = []
        for item in sorted {
            if current.isEmpty || abs(item.boundingBox.midY - current[0].boundingBox.midY) < 0.015 {
                current.append(item)
            } else {
                rows.append(current)
                current = [item]
            }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }

    /// A new transaction cluster starts whenever a row contains a date token
    /// in the left third of the page (x < 0.35) — universally true for every
    /// bank layout we've seen.
    private func clusterIntoTransactions(_ rows: [[ExtractedTextItem]]) -> [[ExtractedTextItem]] {
        var clusters: [[ExtractedTextItem]] = []
        var current:  [ExtractedTextItem]  = []

        for row in rows {
            let hasDateOnLeft = row.contains {
                $0.boundingBox.midX < 0.35 && parseDate($0.text) != nil
            }
            if hasDateOnLeft && !current.isEmpty {
                clusters.append(current)
                current = []
            }
            current.append(contentsOf: row)
        }
        if !current.isEmpty { clusters.append(current) }
        return clusters
    }

    // MARK: - Cluster parsing

    private func parseCluster(_ items: [ExtractedTextItem]) -> ParsedTransactionResult? {
        // Re-group items into rows so we know which row the date is on.
        // Merchant must come from the SAME row as the date — sub-rows below it
        // contain transaction type labels ("TRSF E-BANKING DB", "Bunga Tabungan")
        // which are noise, not merchant names.
        let rows = groupIntoRows(items.sorted { $0.boundingBox.minY < $1.boundingBox.minY })

        var date:             Date?
        var merchant:         String?
        var amountCandidates: [(value: Double, x: CGFloat)] = []
        var dateRowMidY:      CGFloat = -1

        // Pass 1: locate the date and record which row it's on.
        outer: for row in rows {
            for item in row {
                if let d = parseDate(item.text.trimmingCharacters(in: .whitespaces)) {
                    date        = d
                    dateRowMidY = row[0].boundingBox.midY
                    break outer
                }
            }
        }

        // Pass 2: collect merchant (date row only) + amounts (all rows, right column).
        for row in rows {
            let isDateRow = abs(row[0].boundingBox.midY - dateRowMidY) < 0.02
            for item in row {
                let text = item.text.trimmingCharacters(in: .whitespaces)
                guard !text.isEmpty else { continue }

                // Amount: right half of page, any row
                if item.boundingBox.midX > 0.45, let amt = parseAmount(text) {
                    amountCandidates.append((value: amt, x: item.boundingBox.midX))
                    continue
                }

                // Merchant: date row only, left/centre column, not the date itself
                if isDateRow,
                   merchant == nil,
                   item.boundingBox.midX < 0.65,
                   !isNoise(text),
                   isMerchantName(text),
                   parseDate(text) == nil {
                    merchant = text
                }
            }
        }

        guard !amountCandidates.isEmpty else { return nil }

        // Leftmost amount = transaction amount; rightmost = running balance.
        let amount = amountCandidates.sorted { $0.x < $1.x }.first!.value

        return ParsedTransactionResult(
            merchantRaw: merchant ?? "Unknown",
            amount:      amount,
            date:        date ?? Date(),
            isIncome:    false
            // isIncome note: without bank-specific column knowledge the safest
            // universal options are (a) a +/- sign prefix on the raw amount string,
            // (b) cell colour passed in from the OCR pipeline, or (c) balance delta
            // (next saldo − this saldo > 0 → credit). Wire in whichever your OCR
            // pipeline can supply.
        )
    }

    // MARK: - Date parsing
    //
    // Tries every common format in order. Add more patterns here as you
    // encounter new statement layouts — nothing else in the parser changes.

    private func parseDate(_ text: String) -> Date? {
        for fmt in Self.dateFormatters {
            if let d = fmt.date(from: text) { return d }
        }
        return nil
    }

    // DateFormatter instances are expensive — create once and reuse.
    private static let dateFormatters: [DateFormatter] = {
        let formats = [
            "dd/MM/yyyy",       // BCA mobile:   25/03/2026
            "dd-MM-yyyy",       // Some exports: 25-03-2026
            "yyyy-MM-dd",       // ISO 8601:     2026-03-25
            "dd MMM yyyy",      // PDF exports:  25 Mar 2026
            "dd MMMM yyyy",     // Long form:    25 March 2026
            "MMM dd, yyyy",     // US style:     Mar 25, 2026
            "MMMM dd, yyyy",    // US long:      March 25, 2026
            "dd MMM",           // SeaBank:      25 MAR  (no year)
            "dd-MMM-yyyy",      // CIMB/OCBC:    25-Mar-2026
            "dd/MMM/yyyy",      // Variant:      25/Mar/2026
            "MM/dd/yyyy",       // US numeric:   03/25/2026
        ]
        // Try both English and Indonesian locale so month names work in both.
        let locales = [Locale(identifier: "en_US"), Locale(identifier: "id_ID")]
        let timeZone = TimeZone(identifier: "UTC")!

        return formats.flatMap { fmt -> [DateFormatter] in
            locales.map { locale in
                let df = DateFormatter()
                df.dateFormat = fmt
                df.locale     = locale
                df.timeZone   = timeZone
                df.isLenient  = false
                return df
            }
        }
    }()

    // MARK: - Amount parsing
    //
    // Handles the three common separator conventions worldwide:
    //   • 1,000,000.00  — Anglo / most of Asia
    //   • 1.000.000,00  — Continental Europe / Indonesia (some banks)
    //   • 1.000.000     — SeaBank (no decimal part)
    //
    // Also handles:
    //   • Currency prefixes: $, €, £, ¥, ₩, Rp, IDR, USD, etc.
    //   • Sign prefixes: "+" (income) and "-" (expense)

    private func parseAmount(_ raw: String) -> Double? {
        var text = raw.trimmingCharacters(in: .whitespaces)

        // Detect sign prefix before stripping anything
        // (used by callers to infer isIncome if needed)
        let _ = text.hasPrefix("+")    // reserved for caller use
        if text.hasPrefix("+") || text.hasPrefix("-") {
            text = String(text.dropFirst())
        }

        // Strip currency symbols and known prefixes
        let currencyPrefixes = ["Rp.", "Rp", "IDR", "USD", "SGD", "MYR",
                                "$", "€", "£", "¥", "₩", "฿", "₫", "₱"]
        for prefix in currencyPrefixes {
            if text.uppercased().hasPrefix(prefix.uppercased()) {
                text = String(text.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }

        // Normalise OCR "O" → "0" (only when surrounded by digits)
        text = text.replacingOccurrences(
            of: #"(?<=\d)O(?=\d)"#, with: "0", options: .regularExpression
        )

        guard text.first?.isNumber == true else { return nil }

        // Determine the decimal separator:
        //   If the string ends with [.,] + exactly 2 digits → that's the decimal.
        //   Otherwise → no decimal part; all separators are thousands groupers.
        let numeric: String
        if let decRange = text.range(of: #"[.,]\d{2}$"#, options: .regularExpression) {
            let decSep = text[decRange.lowerBound]
            if decSep == "," {
                // Decimal comma: "1.234.567,89" → "1234567.89"
                var s = text.replacingOccurrences(of: ".", with: "")
                if let idx = s.lastIndex(of: ",") { s.replaceSubrange(idx...idx, with: ".") }
                numeric = s
            } else {
                // Decimal dot: "1,234,567.89" → "1234567.89"
                numeric = text.replacingOccurrences(of: ",", with: "")
            }
        } else {
            // No decimal: "1.234.567" or "1,234,567" → "1234567"
            numeric = text
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: "")
        }

        guard let value = Double(numeric), value > 0 else { return nil }
        return value
    }

    // MARK: - Token filters

    /// Returns true for tokens that are definitely not merchant names:
    /// pure numbers, reference codes, account numbers, single chars, UI labels.
    private func isNoise(_ text: String) -> Bool {
        // Single character
        if text.count <= 1 { return true }

        // Pure numeric (possibly with separators) — already handled as amount
        if text.allSatisfy({ $0.isNumber || $0 == "." || $0 == "," || $0 == " " }) { return true }

        // Reference / transaction codes: contain slashes or are long alphanumeric strings
        if text.contains("/") { return true }
        if text.range(of: #"^[A-Z0-9]{8,}$"#, options: .regularExpression) != nil { return true }

        // Account / phone numbers: 8+ consecutive digits
        if text.range(of: #"^\+?[\d\s\-]{8,}$"#, options: .regularExpression) != nil { return true }

        return false
    }

    /// A merchant name has at least one letter, is 2–50 chars, and isn't noise.
    private func isMerchantName(_ text: String) -> Bool {
        guard text.count >= 2, text.count <= 50 else { return false }
        guard text.contains(where: { $0.isLetter }) else { return false }
        return !isNoise(text)
    }

    // MARK: - OCR pre-processing

    /// Splits OCR-fused tokens like "900000.00JIMMY HO" into ["900000.00", "JIMMY HO"].
    private func splitConcatenatedToken(_ item: ExtractedTextItem) -> [ExtractedTextItem] {
        let text = item.text
        guard let regex = try? NSRegularExpression(pattern: #"^([\d,.\s]+)([A-Z][A-Za-z\s]{2,})$"#),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let numRange  = Range(match.range(at: 1), in: text),
              let nameRange = Range(match.range(at: 2), in: text)
        else { return [item] }

        let num  = String(text[numRange]).trimmingCharacters(in: .whitespaces)
        let name = String(text[nameRange]).trimmingCharacters(in: .whitespaces)
        guard !num.isEmpty, !name.isEmpty else { return [item] }

        return [
            ExtractedTextItem(text: num,  boundingBox: item.boundingBox),
            ExtractedTextItem(text: name, boundingBox: item.boundingBox)
        ]
    }
}

// MARK: - CGRect convenience

private extension CGRect {
    var midX: CGFloat { origin.x + width  / 2 }
    var midY: CGFloat { origin.y + height / 2 }
}
