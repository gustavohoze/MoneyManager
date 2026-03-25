import CoreData
import Testing
@testable import Money_Guard

struct ExportServiceTests {
    @Test("Test: CSV export")
    func csvExport_escapesSpecialCharacters() {
        // Objective: Ensure CSV escaping handles commas, quotes, and newlines.
        // Given: A transaction containing quoted/comma merchant text and multiline note.
        // When: makeCSV is called for that transaction.
        // Then: The CSV output contains properly escaped merchant and note values.
        let service = ExportService()
        let transaction = makeTransaction(
            merchant: "Mega, Store \"One\"",
            note: "line1\nline2"
        )

        let csv = service.makeCSV(from: [transaction])

        #expect(csv.contains("\"Mega, Store \"\"One\"\"\""))
        #expect(csv.contains("\"line1\nline2\""))
    }

    @Test("Test: JSON export")
    func jsonExport_includesNoteField() {
        // Objective: Ensure JSON export includes note data.
        // Given: A transaction with a custom note value.
        // When: makeJSON is called.
        // Then: The JSON output includes the note field and expected value.
        let service = ExportService()
        let transaction = makeTransaction(merchant: "Cafe", note: "custom-note")

        let json = service.makeJSON(from: [transaction])

        #expect(json.contains("\"note\""))
        #expect(json.contains("custom-note"))
    }

    private func makeTransaction(merchant: String, note: String) -> NSManagedObject {
        let model = CoreDataModelFactory.makeModel()
        let entity = model.entitiesByName["Transaction"]!
        let object = NSManagedObject(entity: entity, insertInto: nil)

        object.setValue(UUID(), forKey: "id")
        object.setValue(UUID(), forKey: "paymentMethodID")
        object.setValue(15.5, forKey: "amount")
        object.setValue("USD", forKey: "currency")
        object.setValue(Date(), forKey: "date")
        object.setValue(merchant, forKey: "merchantNormalized")
        object.setValue("manual", forKey: "source")
        object.setValue(note, forKey: "note")
        object.setValue(Date(), forKey: "createdAt")

        return object
    }
}
