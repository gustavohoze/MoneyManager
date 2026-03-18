import SwiftUI

struct AddTransactionDetailsSection: View {
    @Binding var selectedDate: Date
    @Binding var note: String
    var focusedField: FocusState<AddTransactionFormField?>.Binding

    var body: some View {
        Section {
            DatePicker(
                "Date",
                selection: $selectedDate,
                displayedComponents: .date
            )

            TextField("Note (optional)", text: $note, axis: .vertical)
                .focused(focusedField, equals: .note)
                .lineLimit(3)
        } header: {
            Text("Details")
        }
    }
}
