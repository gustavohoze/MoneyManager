import Testing
@testable import Money_Guard

struct MerchantResolverTests {
    private let resolver = MerchantResolver()

    @Test("Test: existing merchant")
    func existingMerchant_resolvesAlfamart() {
        // Objective: Normalize known merchant aliases with high confidence.
        // Given: A known raw merchant value for Alfamart.
        // When: resolve(rawMerchantName:) is called.
        // Then: The normalized name is Alfamart and confidence is high.
        let result = resolver.resolve(rawMerchantName: "TRIJAYA PRATAMA TBK")

        #expect(result.normalizedName == "Alfamart")
        #expect(result.confidence > 0.8)
    }

    @Test("Test: unknown merchant")
    func unknownMerchant_keepsRawNameWithLowConfidence() {
        // Objective: Preserve unknown merchants without overconfident mapping.
        // Given: A raw merchant name not in the known dictionary.
        // When: resolve(rawMerchantName:) is called.
        // Then: The same name is returned with low confidence.
        let result = resolver.resolve(rawMerchantName: "Acme Unknown Store")

        #expect(result.normalizedName == "Acme Unknown Store")
        #expect(result.confidence < 0.5)
    }
}
