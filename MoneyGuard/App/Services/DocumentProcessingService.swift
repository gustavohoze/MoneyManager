import Foundation
import Vision
import PDFKit
import UIKit
import CoreGraphics

/// Represents a block of extracted text with its relative bounding box geometry
struct ExtractedTextItem: Equatable {
    let text: String
    /// Bounding box normalized to the image/page coordinates (0.0 to 1.0)
    let boundingBox: CGRect
}

protocol DocumentProcessingServiceProtocol {
    /// Extracts text paragraphs and their bounding boxes from an image using Vision's OCR
    func extractText(from image: UIImage) async throws -> [ExtractedTextItem]
    
    /// Extracts text lines from a given PDF document using PDFKit
    func extractText(from pdfURL: URL) async throws -> [ExtractedTextItem]
}

enum DocumentProcessingError: Error, LocalizedError {
    case imageProcessingFailed
    case validCGImageNotFound
    case invalidPDFDocument
    case emptyDocument
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed: return "Failed to process the image for text extraction."
        case .validCGImageNotFound: return "Could not read the underlying image data."
        case .invalidPDFDocument: return "The provided file is not a valid PDF document."
        case .emptyDocument: return "No text could be found in the document."
        }
    }
}

final class DocumentProcessingService: DocumentProcessingServiceProtocol {
    
    func extractText(from image: UIImage) async throws -> [ExtractedTextItem] {
        debugLog("OCR image extraction started")
        guard let cgImage = image.cgImage else {
            debugLog("OCR image extraction failed: missing CGImage")
            throw DocumentProcessingError.validCGImageNotFound
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    self.debugLog("OCR image extraction completed with 0 observations")
                    continuation.resume(returning: [])
                    return
                }
                
                let extracted = observations.compactMap { observation -> ExtractedTextItem? in
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }
                    let text = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return nil }
                    
                    return ExtractedTextItem(
                        text: text,
                        boundingBox: observation.boundingBox
                    )
                }

                self.debugLog("OCR image extraction completed with \(extracted.count) text items")
                
                continuation.resume(returning: extracted)
            }
            
            // For receipts and bank statements, we need accurate recognition.
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["id-ID", "en-US"]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                self.debugLog("OCR image extraction failed with Vision error: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    func extractText(from pdfURL: URL) async throws -> [ExtractedTextItem] {
        debugLog("PDF extraction started: \(pdfURL.lastPathComponent)")
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            debugLog("PDF extraction failed: invalid PDF document")
            throw DocumentProcessingError.invalidPDFDocument
        }
        
        var extractedItems: [ExtractedTextItem] = []
        
        let pageCount = pdfDocument.pageCount
        guard pageCount > 0 else {
            debugLog("PDF extraction failed: no pages")
            throw DocumentProcessingError.emptyDocument
        }
        debugLog("PDF page count: \(pageCount)")
        
        for i in 0..<pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }

            // Preferred path for text-based statements: extract selectable PDF text by line
            // and convert line bounds into normalized geometry for row reconstruction.
            if let lineItems = extractTextLinesFromPDFPage(page), !lineItems.isEmpty {
                let pageOffset = CGFloat(i)
                let offsetItems = lineItems.map { item in
                    let box = CGRect(
                        x: item.boundingBox.origin.x,
                        y: item.boundingBox.origin.y + pageOffset,
                        width: item.boundingBox.width,
                        height: item.boundingBox.height
                    )
                    return ExtractedTextItem(text: item.text, boundingBox: box)
                }
                debugLog("PDF page \(i + 1): native text extracted \(offsetItems.count) line items")
                extractedItems.append(contentsOf: offsetItems)
                continue
            }

            // Privacy-first pipeline: run Vision OCR on rendered PDF pages so we keep
            // text geometry (bounding boxes) for row reconstruction.
            if let rendered = renderPageImage(page) {
                let pageItems = try await extractText(from: rendered)
                if !pageItems.isEmpty {
                    debugLog("PDF page \(i + 1): Vision extracted \(pageItems.count) items")
                    // Offset each page in Y so row grouping never mixes across pages.
                    let pageOffset = CGFloat(i)
                    let offsetItems = pageItems.map { item in
                        let box = CGRect(
                            x: item.boundingBox.origin.x,
                            y: item.boundingBox.origin.y + pageOffset,
                            width: item.boundingBox.width,
                            height: item.boundingBox.height
                        )
                        return ExtractedTextItem(text: item.text, boundingBox: box)
                    }
                    extractedItems.append(contentsOf: offsetItems)
                    continue
                }
                debugLog("PDF page \(i + 1): Vision returned 0 items, using raw text fallback")
            } else {
                debugLog("PDF page \(i + 1): render failed, using raw text fallback")
            }

            // Fallback to PDF raw text if page rendering/OCR does not produce items.
            if let pageText = page.string {
                let lines = pageText.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                debugLog("PDF page \(i + 1): raw text fallback yielded \(lines.count) lines")

                for line in lines {
                    extractedItems.append(ExtractedTextItem(text: line, boundingBox: .zero))
                }
            }
        }

        if extractedItems.isEmpty {
            debugLog("PDF extraction completed with 0 items")
            throw DocumentProcessingError.emptyDocument
        }

        debugLog("PDF extraction completed with total \(extractedItems.count) items")

        return extractedItems
    }

    private func extractTextLinesFromPDFPage(_ page: PDFPage) -> [ExtractedTextItem]? {
        guard let fullSelection = page.selection(for: page.bounds(for: .mediaBox)) else {
            return nil
        }

        let lines = fullSelection.selectionsByLine()
        guard !lines.isEmpty else { return nil }

        let pageBounds = page.bounds(for: .mediaBox)
        guard pageBounds.width > 0, pageBounds.height > 0 else { return nil }

        var items: [ExtractedTextItem] = []
        items.reserveCapacity(lines.count)

        for lineSelection in lines {
            guard let raw = lineSelection.string?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
                continue
            }

            let bounds = lineSelection.bounds(for: page)
            guard bounds.width > 0, bounds.height > 0 else { continue }

            // PDF coordinates are bottom-left origin; normalize into Vision-like coordinates.
            let normX = bounds.minX / pageBounds.width
            let normY = bounds.minY / pageBounds.height
            let normW = bounds.width / pageBounds.width
            let normH = bounds.height / pageBounds.height

            let normalized = CGRect(x: normX, y: normY, width: normW, height: normH)
            items.append(ExtractedTextItem(text: raw, boundingBox: normalized))
        }

        return items.isEmpty ? nil : items
    }

    private func renderPageImage(_ page: PDFPage) -> UIImage? {
        let pageBounds = page.bounds(for: .mediaBox)
        guard pageBounds.width > 0, pageBounds.height > 0 else { return nil }

        let scale: CGFloat = 2.0
        let renderSize = CGSize(width: pageBounds.width * scale, height: pageBounds.height * scale)
        let renderer = UIGraphicsImageRenderer(size: renderSize)

        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: renderSize))

            context.cgContext.saveGState()
            context.cgContext.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: context.cgContext)
            context.cgContext.restoreGState()
        }
    }

    private func debugLog(_ message: String) {
#if DEBUG
        print("[DocumentProcessingService] \(message)")
#endif
    }
}
