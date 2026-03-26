import Foundation
import SwiftUI
import Combine

@MainActor
final class ScannerViewModel: ObservableObject {
    @Published var selectedImage: UIImage? = nil
    @Published var parsedTransactions: [ParsedTransactionResult] = []
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String? = nil
    
    private let documentService = DocumentProcessingService()
    private let classifier = DocumentClassifier()
    private let bankParser = BankStatementParser()
    private let bankDocumentParser = BankDocumentParser()
    private let receiptParser = ReceiptDocumentParser()
    private let transactionEntryService: TransactionEntryService
    private let accountRepository: PaymentMethodRepository
    
    init(transactionEntryService: TransactionEntryService, accountRepository: PaymentMethodRepository) {
        self.transactionEntryService = transactionEntryService
        self.accountRepository = accountRepository
    }
    
    func processSelectedImage(_ image: UIImage) {
        debugLog("Image processing started")
        self.selectedImage = image
        self.parsedTransactions = []
        self.isProcessing = true
        self.errorMessage = nil
        
        Task {
            do {
                                let preprocessedImage = Helper.preprocess(image) ?? image
                let extractedText = try await documentService.extractText(from: preprocessedImage)
                                debugLog("Image OCR extracted \(extractedText.count) items")
                
                print("================ OCR EXTRACTION RESULTS ===================")
                for (index, item) in extractedText.enumerated() {
                    print("[\(index)] Text: '\(item.text)'")
                    print("    BoundingBox: \(item.boundingBox)")
                }
                print("=========================================================")
                
                let docType = classifier.classify(extractedText: extractedText)
                print("Detected Document Type: \(docType)")
                debugLog("Classifier document type: \(docType)")
                
                var results: [ParsedTransactionResult] = []
                if docType == .receipt {
                    results = receiptParser.parse(extractedItems: extractedText)
                    debugLog("Primary receipt parser produced \(results.count) transactions")
                } else {
                    results = bankParser.parse(extractedItems: extractedText)
                    debugLog("Primary bank statement parser produced \(results.count) transactions")
                }

                if shouldRunFallback(for: results) {
                    debugLog("Primary parser low confidence, running fallback bank document parser")
                    let fallbackResults = bankDocumentParser.parseAll(extractedItems: extractedText)
                    debugLog("Fallback parser produced \(fallbackResults.count) transactions")
                    if fallbackResults.count > results.count {
                        results = fallbackResults
                    }
                }

                if results.isEmpty {
                    debugLog("Image processing completed with 0 parsed transactions")
                    self.errorMessage = "No transactions could be read from this document."
                } else {
                    debugLog("Image processing completed with \(results.count) parsed transactions")
                    logParsedTransactions(results)
                    self.parsedTransactions = results
                }
            } catch {
                debugLog("Image processing failed: \(error.localizedDescription)")
                self.errorMessage = "Failed to process document: \(error.localizedDescription)"
            }
            self.isProcessing = false
        }
    }

    func processSelectedPDF(_ pdfURL: URL) {
        debugLog("PDF processing started: \(pdfURL.lastPathComponent)")
        self.selectedImage = nil
        self.parsedTransactions = []
        self.isProcessing = true
        self.errorMessage = nil

        Task {
            do {
                let extractedText = try await documentService.extractText(from: pdfURL)
                debugLog("PDF extraction produced \(extractedText.count) items")

                for (index, item) in extractedText.prefix(80).enumerated() {
                    debugLog("pdf-item[\(index)] text=\(item.text) bbox=\(item.boundingBox)")
                }

                let docType = classifier.classify(extractedText: extractedText)
                debugLog("Classifier document type: \(docType)")

                var results: [ParsedTransactionResult] = []
                if docType == .receipt {
                    results = receiptParser.parse(extractedItems: extractedText)
                    debugLog("Primary receipt parser produced \(results.count) transactions")
                } else {
                    results = bankParser.parse(extractedItems: extractedText)
                    debugLog("Primary bank statement parser produced \(results.count) transactions")
                }

                if shouldRunFallback(for: results) {
                    debugLog("Primary parser low confidence, running fallback bank document parser")
                    let fallbackResults = bankDocumentParser.parseAll(extractedItems: extractedText)
                    debugLog("Fallback parser produced \(fallbackResults.count) transactions")
                    if fallbackResults.count > results.count {
                        results = fallbackResults
                    }
                }

                if results.isEmpty {
                    debugLog("PDF processing completed with 0 parsed transactions")
                    self.errorMessage = "No transactions could be read from this document."
                } else {
                    debugLog("PDF processing completed with \(results.count) parsed transactions")
                    logParsedTransactions(results)
                    self.parsedTransactions = results
                }
            } catch {
                debugLog("PDF processing failed: \(error.localizedDescription)")
                self.errorMessage = "Failed to process PDF: \(error.localizedDescription)"
            }

            self.isProcessing = false
        }
    }
    
    func removeTransaction(at index: Int) {
        guard index >= 0 && index < parsedTransactions.count else { return }
        parsedTransactions.remove(at: index)
    }
    
    func saveAllTransactions() {
        guard !parsedTransactions.isEmpty else { return }
        isProcessing = true
        
        do {
            let defaultAccountID = try accountRepository.ensureDefaultPaymentMethod()
            
            for tx in parsedTransactions {
                // If it's a negative amount in statement but listed as income vs expense
                // For now, positive means income, negative means expense? Wait, our app defines transaction amount signing logic.
                let actualAmount = tx.isIncome ? tx.amount : -(abs(tx.amount))
                
                _ = try transactionEntryService.saveManualTransaction(
                    paymentMethodID: defaultAccountID,
                    amount: actualAmount,
                    currency: "USD", // Might want to localize or support multi-currency
                    date: tx.date,
                    merchantRaw: tx.merchantRaw,
                    categoryID: nil,
                    note: "Manually imported via OCR"
                )
            }
            
            self.parsedTransactions = []
            self.selectedImage = nil
            self.errorMessage = "Saved successfully!"
        } catch {
            self.errorMessage = "Failed to save: \(error.localizedDescription)"
        }
        isProcessing = false
    }
}

private extension ScannerViewModel {
    func debugLog(_ message: String) {
#if DEBUG
        print("[ScannerViewModel] \(message)")
#endif
    }

    func logParsedTransactions(_ transactions: [ParsedTransactionResult]) {
#if DEBUG
        for (index, tx) in transactions.enumerated() {
            debugLog(
                "tx[\(index)] merchant=\(tx.merchantRaw) amount=\(tx.amount) date=\(tx.date) income=\(tx.isIncome)"
            )
        }
#endif
    }

    func shouldRunFallback(for transactions: [ParsedTransactionResult]) -> Bool {
        if transactions.isEmpty { return true }
        if transactions.count <= 1 { return true }

        let unknownCount = transactions.filter { tx in
            tx.merchantRaw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "unknown"
                || tx.merchantRaw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "unknown merchant"
        }.count

        let unknownRatio = Double(unknownCount) / Double(max(transactions.count, 1))
        return unknownRatio >= 0.5
    }
}

enum Helper {
    static func preprocess(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        // Simple CIImage filter to increase contrast
        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIColorControls") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(1.2, forKey: kCIInputContrastKey) // Boost contrast
        filter.setValue(0.8, forKey: kCIInputSaturationKey) // Boost saturation
        
        // Optional: Convert to grayscale for better OCR sometimes
        // let monoFilter = CIFilter(name: "CIPhotoEffectMono")
        
        let context = CIContext(options: nil)
        guard let output = filter.outputImage,
              let preprocessedCgImage = context.createCGImage(output, from: output.extent) else {
            return nil
        }
        return UIImage(cgImage: preprocessedCgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
