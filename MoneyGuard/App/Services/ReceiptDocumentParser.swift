import Foundation
import CoreGraphics

final class ReceiptDocumentParser {

    func parse(extractedItems: [ExtractedTextItem]) -> [ParsedTransactionResult] {
        var results: [ParsedTransactionResult] = []
        guard !extractedItems.isEmpty else { return [] }
        
        var globalDate: Date?
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            for item in extractedItems {
                let text = item.text
                let matches = detector.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                if let match = matches.first, let foundDate = match.date {
                    let currentYear = Calendar.current.component(.year, from: Date())
                    let foundYear = Calendar.current.component(.year, from: foundDate)
                    if abs(currentYear - foundYear) < 5 {
                        globalDate = foundDate
                        break
                    }
                }
            }
        }
        let receiptDate = globalDate ?? Date()
        
        let amountRegex = try? NSRegularExpression(pattern: "(?<!\\\\d)\\\\d{1,3}(?:[., ]?\\\\d{3})*(?:[.,]\\\\d{1,2})?(?!\\\\d)", options: [])
        
        let sortedByY = extractedItems.sorted(by: { $0.boundingBox.midY > $1.boundingBox.midY })
        
        var rows: [[ExtractedTextItem]] = []
        var currentRow: [ExtractedTextItem] = [sortedByY[0]]
        
        for item in sortedByY.dropFirst() {
            let lastItem = currentRow.last!
            let yDiff = abs(item.boundingBox.midY - lastItem.boundingBox.midY)
            if yDiff < 0.02 {
                currentRow.append(item)
            } else {
                currentRow.sort(by: { $0.boundingBox.minX < $1.boundingBox.minX })
                rows.append(currentRow)
                currentRow = [item]
            }
        }
        currentRow.sort(by: { $0.boundingBox.minX < $1.boundingBox.minX })
        rows.append(currentRow)
        
        let skipKeywords = ["receipt", "tax", "total", "cash", "change", "visa", "mastercard"]
        
        for row in rows {
            var amountFound: Double?
            var merchantParts: [String] = []
            
            for item in row {
                let text = item.text
                let cleanedText = text.replacingOccurrences(of: "Rp", with: " ", options: .caseInsensitive).replacingOccurrences(of: "IDR", with: " ", options: .caseInsensitive).replacingOccurrences(of: "$", with: " ")
                
                var matchedAmountInThisItem: Double?
                
                if let regex = amountRegex {
                    let matches = regex.matches(in: cleanedText, options: [], range: NSRange(cleanedText.startIndex..., in: cleanedText))
                    for match in matches {
                        guard let range = Range(match.range, in: cleanedText) else { continue }
                        let matchedString = String(cleanedText[range]).trimmingCharacters(in: .whitespaces)
                        if let parsedAmount = parseAmount(matchedString), parsedAmount > 0 && parsedAmount < 1_000_000_000 {
                            matchedAmountInThisItem = parsedAmount
                        }
                    }
                }
                
                if let amt = matchedAmountInThisItem {
                    amountFound = amt
                } else {
                    let lower = text.lowercased()
                    let isCommonNoise = skipKeywords.contains(where: { lower.contains($0) })
                    let isNumeric = Double(text.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "").replacingOccurrences(of: " ", with: "")) != nil
                    
                    if !isCommonNoise && !isNumeric && text.count > 1 {
                        merchantParts.append(text)
                    }
                }
            }
            if let finalAmount = amountFound, !merchantParts.isEmpty {
                let finalMerchant = merchantParts.joined(separator: " ")
                let lowerMerch = finalMerchant.lowercased()
                if skipKeywords.contains(where: { lowerMerch.contains($0) }) {
                    continue
                }
                
                results.append(ParsedTransactionResult(
                    merchantRaw: finalMerchant,
                    amount: finalAmount,
                    date: receiptDate,
                    isIncome: false
                ))
            }
        }
        
        return results
    }
    
    private func parseAmount(_ string: String) -> Double? {
        let rawNumber = string.replacingOccurrences(of: " ", with: "")
        let lastDotIndex = rawNumber.lastIndex(of: ".")
        let lastCommaIndex = rawNumber.lastIndex(of: ",")
        
        var decimalSeparatorIndex: String.Index? = nil
        if let dIdx = lastDotIndex, let cIdx = lastCommaIndex {
            decimalSeparatorIndex = dIdx > cIdx ? dIdx : cIdx
        } else {
            decimalSeparatorIndex = lastDotIndex ?? lastCommaIndex
        }
        
        var isDecimal = false
        if let sepIdx = decimalSeparatorIndex {
            let distance = rawNumber.distance(from: sepIdx, to: rawNumber.endIndex)
            if distance == 2 || distance == 3 {
                isDecimal = true
            }
        }
        
        if isDecimal, let sepIdx = decimalSeparatorIndex {
            let integerPart = rawNumber[..<sepIdx].replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "")
            let fractionPart = rawNumber[rawNumber.index(after: sepIdx)...]
            return Double("\\(integerPart).\\(fractionPart)")
        } else {
            let justDigits = rawNumber.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "")
            return Double(justDigits)
        }
    }
}
