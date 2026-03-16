import CoreData
import Foundation

struct ExportService {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    func makeCSV(from transactions: [NSManagedObject]) -> String {
        var lines = ["date,merchant,amount,currency,source,note"]

        for transaction in transactions {
            let date = (transaction.value(forKey: "date") as? Date).map(dateFormatter.string) ?? ""
            let merchant = (transaction.value(forKey: "merchantNormalized") as? String) ?? ""
            let amount = String((transaction.value(forKey: "amount") as? Double) ?? 0)
            let currency = (transaction.value(forKey: "currency") as? String) ?? ""
            let source = (transaction.value(forKey: "source") as? String) ?? ""
            let note = (transaction.value(forKey: "note") as? String) ?? ""

            lines.append([
                escapeForCSV(date),
                escapeForCSV(merchant),
                escapeForCSV(amount),
                escapeForCSV(currency),
                escapeForCSV(source),
                escapeForCSV(note)
            ].joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    func makeJSON(from transactions: [NSManagedObject]) -> String {
        let rows: [[String: Any]] = transactions.map { transaction in
            [
                "id": (transaction.value(forKey: "id") as? UUID)?.uuidString ?? "",
                "date": (transaction.value(forKey: "date") as? Date).map(dateFormatter.string) ?? "",
                "merchant": (transaction.value(forKey: "merchantNormalized") as? String) ?? "",
                "amount": (transaction.value(forKey: "amount") as? Double) ?? 0,
                "currency": (transaction.value(forKey: "currency") as? String) ?? "",
                "source": (transaction.value(forKey: "source") as? String) ?? "",
                "note": (transaction.value(forKey: "note") as? String) ?? ""
            ]
        }

        guard let data = try? JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted]),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "[]"
        }

        return jsonString
    }

    private func escapeForCSV(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            return "\"\(escaped)\""
        }
        return escaped
    }
}
