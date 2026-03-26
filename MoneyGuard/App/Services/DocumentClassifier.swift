import Foundation

enum DocumentType {
    case receipt
    case bankStatement
    case unknown
}

protocol DocumentClassifierProtocol {
    /// Determines the most likely type of document based on its extracted text
    func classify(extractedText: [ExtractedTextItem]) -> DocumentType
}

final class DocumentClassifier: DocumentClassifierProtocol {
    
    // Keywords frequently found on retail or restaurant receipts
    private let receiptKeywords: Set<String> = [
        "total", "subtotal", "tax", "cash", "change", "receipt", "visa", "mastercard",
        "qty", "amount due", "tip", "gratuity", "card", "pajak", "tunai", "kembali"
    ]
    
    // Keywords frequently found on bank statements or banking app screenshots
    private let bankKeywords: Set<String> = [
        "balance", "statement", "account", "transfer", "debit", "credit", "db", "cr",
        "available balance", "ending balance", "rekening", "saldo", "mutasi"
    ]
    
    func classify(extractedText: [ExtractedTextItem]) -> DocumentType {
        var receiptScore = 0
        var bankScore = 0
        
        for item in extractedText {
            let text = item.text.lowercased()
            
            // Exact match weighting (token based)
            let tokens = text.components(separatedBy: .whitespacesAndNewlines)
            
            for token in tokens {
                let cleanToken = token.trimmingCharacters(in: .punctuationCharacters)
                
                if receiptKeywords.contains(cleanToken) {
                    receiptScore += 1
                }
                if bankKeywords.contains(cleanToken) {
                    bankScore += 1
                }
            }
        }
        
        // Return .unknown if we don't have enough confidence
        if receiptScore == 0 && bankScore == 0 {
            return .unknown
        }
        
        return receiptScore >= bankScore ? .receipt : .bankStatement
    }
}
