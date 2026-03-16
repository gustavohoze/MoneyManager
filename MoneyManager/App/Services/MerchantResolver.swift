import Foundation

struct MerchantResolutionResult {
    let normalizedName: String
    let confidence: Double
}

protocol MerchantResolving {
    func resolve(rawMerchantName: String) -> MerchantResolutionResult
}

struct MerchantResolver: MerchantResolving {
    func resolve(rawMerchantName: String) -> MerchantResolutionResult {
        let uppercased = rawMerchantName.uppercased()

        if uppercased.contains("TRIJAYA") || uppercased.contains("ALFAMART") {
            return MerchantResolutionResult(normalizedName: "Alfamart", confidence: 0.92)
        }

        if uppercased.contains("STARBUCKS") {
            return MerchantResolutionResult(normalizedName: "Starbucks", confidence: 0.98)
        }

        if uppercased.contains("GRAB") {
            return MerchantResolutionResult(normalizedName: "Grab", confidence: 0.96)
        }

        return MerchantResolutionResult(normalizedName: rawMerchantName.capitalized, confidence: 0.40)
    }
}
