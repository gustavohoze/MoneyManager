import re

path = "./MoneyGuard/App/ViewModels/Scanner/ScannerViewModel.swift"
with open(path, "r") as f:
    orig = f.read()

new_code = orig.replace(
    "private let listParser = BankStatementParser()",
    "private let classifier = DocumentClassifier()\n    private let bankParser = BankStatementParser()\n    private let receiptParser = ReceiptDocumentParser()"
)

new_code = new_code.replace(
    "let results = listParser.parse(extractedItems: extractedText)",
    """let docType = classifier.classify(extractedText: extractedText)
                var results: [ParsedTransactionResult] = []
                if docType == .receipt {
                    if let receiptResult = receiptParser.parse(extractedItems: extractedText) {
                        results.append(receiptResult)
                    }
                } else {
                    results = bankParser.parse(extractedItems: extractedText)
                }"""
)

with open(path, "w") as f:
    f.write(new_code)
