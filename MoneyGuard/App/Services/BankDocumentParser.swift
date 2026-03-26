import Foundation
import CoreGraphics

protocol DocumentParserProtocol {
    /// Attempts to extract transaction details from textual items
    func parse(extractedItems: [ExtractedTextItem]) -> ParsedTransactionResult?
}

final class BankDocumentParser {

    // Compatibility wrapper for older call sites.
    func parse(extractedItems: [ExtractedTextItem]) -> ParsedTransactionResult? {
        parseAll(extractedItems: extractedItems).first
    }

    // Heuristic multi-transaction parser for Bank Screenshots and PDFs.
    func parseAll(extractedItems: [ExtractedTextItem]) -> [ParsedTransactionResult] {
        guard !extractedItems.isEmpty else { return [] }
        debugLog("parseAll started with \(extractedItems.count) items")

        // If geometry exists, reconstruct statement rows by Y-alignment first.
        let hasGeometry = extractedItems.contains { $0.boundingBox != .zero }
        debugLog("geometry available: \(hasGeometry)")
        let parsed: [ParsedTransactionResult]
        if hasGeometry {
            parsed = parseUsingGeometry(extractedItems)
        } else {
            parsed = parseTextOnly(extractedItems)
        }

        debugLog("parsed before dedupe: \(parsed.count)")

        // Dedupe noisy OCR duplicates while preserving original order.
        var seen: Set<String> = []
        let deduped = parsed.filter { tx in
            let amountKey = String(format: "%.2f", tx.amount)
            let minuteBucket = String(format: "%.0f", (tx.date.timeIntervalSince1970 / 60.0).rounded())
            let key = "\(tx.merchantRaw.lowercased())|\(amountKey)|\(minuteBucket)|\(tx.isIncome)"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
        debugLog("parsed after dedupe: \(deduped.count)")
        return deduped
    }

    private func parseUsingGeometry(_ extractedItems: [ExtractedTextItem]) -> [ParsedTransactionResult] {
        let rows = buildRows(extractedItems)
        debugLog("geometry mode rows: \(rows.count)")
        guard !rows.isEmpty else {
            debugLog("geometry mode aborted: 0 rows")
            return []
        }

        var results: [ParsedTransactionResult] = []
        var currentDate: Date? = nil
        let statementYear = detectStatementYear(from: extractedItems) ?? Calendar.current.component(.year, from: Date())
        debugLog("geometry mode statementYear=\(statementYear)")

        for (rowIndex, row) in rows.enumerated() {
            let line = row.map { $0.text }.joined(separator: " ")
            let normalizedLine = normalizeNumericFragments(in: line)
            let rowPreview = String(line.prefix(120))
            debugLog("row[\(rowIndex)] items=\(row.count) text=\(rowPreview)")

            if isBalanceLine(normalizedLine) {
                debugLog("row[\(rowIndex)] skipped as balance line")
                continue
            }

            guard let rowDate = extractTransactionRowDate(from: row, fallbackYear: statementYear) else {
                debugLog("row[\(rowIndex)] skipped: no left-column transaction date")
                continue
            }
            currentDate = rowDate
            debugLog("row[\(rowIndex)] row date=\(rowDate)")

            let merchant = extractMerchantFromMiddleColumn(row)
            guard let merchant, !merchant.isEmpty else {
                debugLog("row[\(rowIndex)] skipped: no middle-column merchant")
                continue
            }

            var amountCandidates: [Double] = []

            // Prefer right-side numeric tokens because transaction/balance columns are tabular.
            let rightToLeft = row.sorted { $0.boundingBox.midX > $1.boundingBox.midX }
            for item in rightToLeft {
                guard item.boundingBox.midX > 0.45 else { continue }
                let token = normalizeNumericFragments(in: item.text)
                let parsedValues = extractAmounts(in: token)
                for parsed in parsedValues where abs(parsed) > 0 {
                    amountCandidates.append(parsed)
                }
            }

            if amountCandidates.isEmpty {
                amountCandidates = extractAmounts(in: normalizedLine)
                    .filter { _ in true }
            }

            guard !amountCandidates.isEmpty else {
                debugLog("row[\(rowIndex)] skipped: no amount candidates")
                continue
            }

            let amount = amountCandidates.min(by: { abs($0) < abs($1) }) ?? amountCandidates[0]
            guard abs(amount) > 0 else {
                debugLog("row[\(rowIndex)] skipped: amount is zero")
                continue
            }

            let inferredIncome = inferIncome(in: normalizedLine, amount: amount)

            debugLog("row[\(rowIndex)] parsed tx merchant=\(merchant) amount=\(abs(amount)) income=\(inferredIncome)")

            results.append(
                ParsedTransactionResult(
                    merchantRaw: merchant,
                    amount: abs(amount),
                    date: currentDate ?? Date(),
                    isIncome: inferredIncome
                )
            )
        }

        debugLog("geometry mode produced \(results.count) transactions")

        return results
    }

    private func parseTextOnly(_ extractedItems: [ExtractedTextItem]) -> [ParsedTransactionResult] {
        let lines = extractedItems
            .map { normalizeNumericFragments(in: $0.text.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.isEmpty }

        debugLog("text-only mode lines: \(lines.count)")
        guard !lines.isEmpty else {
            debugLog("text-only mode aborted: 0 lines")
            return []
        }

        var results: [ParsedTransactionResult] = []
        var currentDate: Date? = nil

        for (index, line) in lines.enumerated() {
            if let dateInLine = detectDate(in: line) {
                currentDate = dateInLine
            }

            if isBalanceLine(line) {
                continue
            }

            let amountCandidates = extractAmounts(in: line)
            guard !amountCandidates.isEmpty else { continue }

            let amount = amountCandidates.min(by: { abs($0) < abs($1) }) ?? amountCandidates[0]
            guard abs(amount) > 0 else { continue }

            let merchant = extractMerchant(from: line)
                ?? findNearbyMerchant(lines: lines, around: index)
                ?? "Unknown Merchant"

            let inferredIncome = inferIncome(in: line, amount: amount)

            results.append(
                ParsedTransactionResult(
                    merchantRaw: merchant,
                    amount: abs(amount),
                    date: currentDate ?? Date(),
                    isIncome: inferredIncome
                )
            )
        }

        debugLog("text-only mode produced \(results.count) transactions")

        return results
    }

    private func buildRows(_ extractedItems: [ExtractedTextItem]) -> [[ExtractedTextItem]] {
        let items = extractedItems
            .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { lhs, rhs in
                if lhs.boundingBox.midY == rhs.boundingBox.midY {
                    return lhs.boundingBox.minX < rhs.boundingBox.minX
                }
                return lhs.boundingBox.midY > rhs.boundingBox.midY
            }

        guard !items.isEmpty else { return [] }

        let heights = items.map { max($0.boundingBox.height, 0.01) }
        let avgHeight = heights.reduce(0, +) / CGFloat(heights.count)
        let yTolerance = max(0.012, min(0.03, avgHeight * 0.75))
        debugLog("row builder avgHeight=\(avgHeight) yTolerance=\(yTolerance)")

        var rows: [[ExtractedTextItem]] = []
        var current: [ExtractedTextItem] = []
        var currentMidY: CGFloat = items[0].boundingBox.midY

        for item in items {
            let y = item.boundingBox.midY
            if current.isEmpty || abs(y - currentMidY) <= yTolerance {
                current.append(item)
                currentMidY = (currentMidY * CGFloat(current.count - 1) + y) / CGFloat(current.count)
            } else {
                rows.append(current.sorted { $0.boundingBox.minX < $1.boundingBox.minX })
                current = [item]
                currentMidY = y
            }
        }

        if !current.isEmpty {
            rows.append(current.sorted { $0.boundingBox.minX < $1.boundingBox.minX })
        }

        debugLog("row builder output rows=\(rows.count)")

        return rows
    }

    private func detectDate(in text: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }

        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return matches.first?.date
    }

    private func extractAmounts(in text: String) -> [Double] {
        let amountRegex = try? NSRegularExpression(
            pattern: "(?:Rp|IDR|USD|\\$)?\\s*([+-]?\\d{1,3}(?:[.,\\s]\\d{3})*(?:[.,]\\d{1,2})?|[+-]?\\d+(?:[.,]\\d{1,2})?)",
            options: .caseInsensitive
        )

        guard let amountRegex else { return [] }

        let matches = amountRegex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        var amounts: [Double] = []

        for match in matches {
            guard let range = Range(match.range(at: 1), in: text) else { continue }
            let amountStr = normalizeNumericFragments(in: String(text[range]))
            if let parsedAmount = parseAmount(amountStr), abs(parsedAmount) > 0 {
                amounts.append(parsedAmount)
            }
        }

        return amounts
    }

    private func isBalanceLine(_ text: String) -> Bool {
        let lower = text.lowercased()
        let balanceKeywords = ["balance", "available balance", "ending balance", "saldo", "saldo akhir"]
        return balanceKeywords.contains(where: { lower.contains($0) })
    }

    private func extractMerchant(from text: String) -> String? {
        var cleaned = text

        // Remove numbers/currency fragments.
        if let amountRegex = try? NSRegularExpression(
            pattern: "(?:Rp|IDR|USD|\\$)?\\s*[+-]?\\d+(?:[.,]\\d{3})*(?:[.,]\\d{1,2})?",
            options: .caseInsensitive
        ) {
            cleaned = amountRegex.stringByReplacingMatches(
                in: cleaned,
                options: [],
                range: NSRange(location: 0, length: cleaned.utf16.count),
                withTemplate: " "
            )
        }

        // Remove simple date-like tokens.
        if let dateRegex = try? NSRegularExpression(
            pattern: "\\b\\d{1,2}[/-]\\d{1,2}(?:[/-]\\d{2,4})?\\b|\\b\\d{1,2}\\s+[A-Za-z]{3,9}(?:\\s+\\d{2,4})?\\b",
            options: []
        ) {
            cleaned = dateRegex.stringByReplacingMatches(
                in: cleaned,
                options: [],
                range: NSRange(location: 0, length: cleaned.utf16.count),
                withTemplate: " "
            )
        }

        cleaned = cleaned
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let lower = cleaned.lowercased()
        let skipKeywords = ["balance", "account", "rp", "idr", "transfer", "date", "time", "debit", "credit", "saldo", "dr", "cr"]
        if skipKeywords.contains(where: { lower.contains($0) }) {
            return nil
        }

        guard cleaned.count > 2, cleaned.count < 80 else { return nil }
        guard cleaned.contains(where: { $0.isLetter }) else { return nil }
        return cleaned
    }

    private func findNearbyMerchant(lines: [String], around index: Int) -> String? {
        let candidates = [index - 1, index + 1]
        for candidateIndex in candidates where lines.indices.contains(candidateIndex) {
            let line = lines[candidateIndex]
            if extractAmounts(in: line).isEmpty,
               !isBalanceLine(line),
               let merchant = extractMerchant(from: line) {
                return merchant
            }
        }
        return nil
    }

    private func inferIncome(in text: String, amount: Double) -> Bool {
        let lower = text.lowercased()
        if lower.contains(" cr") || lower.contains("credit") || lower.contains("masuk") {
            return true
        }
        if lower.contains(" dr") || lower.contains("debit") || lower.contains("keluar") {
            return false
        }
        return amount > 0 && text.contains("+")
    }

    private func parseAmount(_ raw: String) -> Double? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        let isNegative = text.hasPrefix("-")
        var valueText = text
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")

        let lastDot = valueText.lastIndex(of: ".")
        let lastComma = valueText.lastIndex(of: ",")

        if let dot = lastDot, let comma = lastComma {
            if dot > comma {
                valueText = valueText.replacingOccurrences(of: ",", with: "")
            } else {
                valueText = valueText.replacingOccurrences(of: ".", with: "")
                if let idx = valueText.lastIndex(of: ",") {
                    valueText.replaceSubrange(idx...idx, with: ".")
                }
            }
        } else if let comma = lastComma {
            let decimals = valueText.distance(from: comma, to: valueText.endIndex) - 1
            if decimals == 2 {
                if let idx = valueText.lastIndex(of: ",") {
                    valueText.replaceSubrange(idx...idx, with: ".")
                }
            } else {
                valueText = valueText.replacingOccurrences(of: ",", with: "")
            }
        } else {
            let parts = valueText.split(separator: ".")
            if parts.count > 1, parts.last?.count == 2 {
                valueText = parts.dropLast().joined() + "." + parts.last!
            } else {
                valueText = valueText.replacingOccurrences(of: ".", with: "")
            }
        }

        guard let parsed = Double(valueText) else { return nil }
        return isNegative ? -parsed : parsed
    }

    private func parseNumericTokenLoosely(_ raw: String) -> Double? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.contains(where: { $0.isNumber }) else { return nil }

        // Keep only sign and numeric separators, then parse with existing amount parser.
        let filtered = text.filter { ch in
            ch.isNumber || ch == "." || ch == "," || ch == "-" || ch == "+" || ch == " "
        }

        return parseAmount(filtered)
    }

    private func detectStatementYear(from extractedItems: [ExtractedTextItem]) -> Int? {
        let joined = extractedItems.map { $0.text }.joined(separator: " ")
        guard let regex = try? NSRegularExpression(pattern: "\\b(20\\d{2})\\b") else { return nil }
        let matches = regex.matches(in: joined, range: NSRange(location: 0, length: joined.utf16.count))
        for match in matches {
            guard let range = Range(match.range(at: 1), in: joined) else { continue }
            if let year = Int(joined[range]) {
                return year
            }
        }
        return nil
    }

    private func extractTransactionRowDate(from row: [ExtractedTextItem], fallbackYear: Int) -> Date? {
        let leftItems = row.filter { $0.boundingBox.midX < 0.22 }
        for item in leftItems {
            if let date = parseDayMonthDate(item.text, fallbackYear: fallbackYear) {
                return date
            }
        }
        return nil
    }

    private func parseDayMonthDate(_ raw: String, fallbackYear: Int) -> Date? {
        let text = raw.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard let regex = try? NSRegularExpression(pattern: "\\b(\\d{1,2})\\s+([A-Z]{3})\\b") else { return nil }
        let nsRange = NSRange(location: 0, length: text.utf16.count)
        guard let match = regex.firstMatch(in: text, range: nsRange),
              let dayRange = Range(match.range(at: 1), in: text),
              let monthRange = Range(match.range(at: 2), in: text),
              let day = Int(text[dayRange]) else {
            return nil
        }

        let monthMap: [String: Int] = [
            "JAN": 1, "FEB": 2, "MAR": 3, "APR": 4, "MEI": 5, "MAY": 5, "JUN": 6,
            "JUL": 7, "AGU": 8, "AUG": 8, "SEP": 9, "OKT": 10, "OCT": 10, "NOV": 11, "DES": 12, "DEC": 12
        ]

        let monthToken = String(text[monthRange])
        guard let month = monthMap[monthToken] else { return nil }

        var comps = DateComponents()
        comps.year = fallbackYear
        comps.month = month
        comps.day = day
        comps.hour = 12
        return Calendar.current.date(from: comps)
    }

    private func extractMerchantFromMiddleColumn(_ row: [ExtractedTextItem]) -> String? {
        let parts = row
            .filter { $0.boundingBox.midX >= 0.20 && $0.boundingBox.midX <= 0.66 }
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { part in
                let lower = part.lowercased()
                if lower == "transfer" || lower == "bunga" || lower == "pajak" || lower == "pembayaran" {
                    return true
                }
                // Keep text-like fragments and remove purely numeric fragments.
                return part.contains(where: { $0.isLetter })
            }

        guard !parts.isEmpty else { return nil }
        let merged = parts.joined(separator: " ")
        return extractMerchant(from: merged)
    }

    private func normalizeNumericFragments(in text: String) -> String {
        var output = text

        // OCR can split decimal separator: "1234 , 56" or "1234 . 56".
        output = output.replacingOccurrences(
            of: #"(?<=\d)\s*([.,])\s*(?=\d)"#,
            with: "$1",
            options: .regularExpression
        )

        return output
    }

    private func debugLog(_ message: String) {
#if DEBUG
        print("[BankDocumentParser] \(message)")
#endif
    }
}
