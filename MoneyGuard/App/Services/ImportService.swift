import CoreData
import Foundation

struct ImportService {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func importFromJSON(_ jsonData: Data) throws -> (transactionsImported: Int, categoriesImported: Int) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            throw ImportError.invalidFormat
        }

        var transactionsImported = 0
        var categoriesImported = 0

        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        try context.performAndWait {
            for item in json {
                // Check if this is a transaction or category based on fields
                if let date = item["date"] as? String,
                   let amount = item["amount"] as? NSNumber,
                   let currency = item["currency"] as? String {
                    // This is a transaction
                    let transaction = NSEntityDescription.insertNewObject(forEntityName: "Transaction", into: context)
                    transaction.setValue(UUID(), forKey: "id")
                    transaction.setValue(dateFormatter.date(from: date), forKey: "date")
                    transaction.setValue(item["merchant"] as? String ?? "", forKey: "merchantNormalized")
                    transaction.setValue(amount.doubleValue, forKey: "amount")
                    transaction.setValue(currency, forKey: "currency")
                    transaction.setValue(item["source"] as? String ?? "", forKey: "source")
                    transaction.setValue(item["note"] as? String ?? "", forKey: "note")
                    transactionsImported += 1
                } else if let name = item["name"] as? String, let type = item["type"] as? String {
                    // This is a category
                    let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context)
                    category.setValue(UUID(), forKey: "id")
                    category.setValue(name, forKey: "name")
                    category.setValue(type, forKey: "type")
                    category.setValue(item["icon"] as? String ?? "tag", forKey: "icon")
                    categoriesImported += 1
                }
            }

            try context.save()
        }

        return (transactionsImported, categoriesImported)
    }

    func importFromCSV(_ csvData: Data) throws -> (transactionsImported: Int, categoriesImported: Int) {
        guard let csvString = String(data: csvData, encoding: .utf8) else {
            throw ImportError.invalidEncoding
        }

        let lines = csvString.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else {
            throw ImportError.emptyFile
        }

        let headers = parseCSVLine(lines[0])
        var transactionsImported = 0

        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        try context.performAndWait {
            for i in 1 ..< lines.count {
                let values = parseCSVLine(lines[i])
                guard values.count == headers.count else { continue }

                let row = Dictionary(uniqueKeysWithValues: zip(headers, values))

                guard let dateString = row["date"], let amountString = row["amount"],
                      let amount = Double(amountString) else {
                    continue
                }

                let transaction = NSEntityDescription.insertNewObject(forEntityName: "Transaction", into: context)
                transaction.setValue(UUID(), forKey: "id")
                transaction.setValue(dateFormatter.date(from: dateString), forKey: "date")
                transaction.setValue(row["merchant"] ?? "", forKey: "merchantNormalized")
                transaction.setValue(amount, forKey: "amount")
                transaction.setValue(row["currency"] ?? "", forKey: "currency")
                transaction.setValue(row["source"] ?? "", forKey: "source")
                transaction.setValue(row["note"] ?? "", forKey: "note")
                transactionsImported += 1
            }

            try context.save()
        }

        return (transactionsImported, 0)
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var insideQuotes = false
        var i = line.startIndex

        while i < line.endIndex {
            let char = line[i]

            if char == "\"" {
                if insideQuotes && i < line.index(before: line.endIndex) && line[line.index(after: i)] == "\"" {
                    currentValue.append("\"")
                    i = line.index(after: i)
                } else {
                    insideQuotes.toggle()
                }
            } else if char == "," && !insideQuotes {
                values.append(currentValue)
                currentValue = ""
            } else {
                currentValue.append(char)
            }

            i = line.index(after: i)
        }

        values.append(currentValue)
        return values.map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

enum ImportError: LocalizedError {
    case invalidFormat
    case invalidEncoding
    case emptyFile
    case corruptedData

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return String(localized: "Invalid file format. Please use JSON or CSV.")
        case .invalidEncoding:
            return String(localized: "File encoding is not supported.")
        case .emptyFile:
            return String(localized: "The file is empty.")
        case .corruptedData:
            return String(localized: "The file contains corrupted data.")
        }
    }
}
