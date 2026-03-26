import Foundation

/// Defines the extracted payload from an OCR/PDF document
struct ParsedTransactionResult: Equatable, Codable {
    let merchantRaw: String
    let amount: Double
    let date: Date
    let isIncome: Bool // Important for bank screenshots where we might capture a transfer IN instead of OUT
}
