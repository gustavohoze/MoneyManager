import SwiftUI

struct AddTransactionCategorySection: View {
    let categories: [TransactionFormCategoryOption]
    let selectedCategoryID: UUID?
    let selectedCategoryName: String
    let onSelect: (UUID) -> Void

    var body: some View {
        Section {
            Menu {
                ForEach(categories) { cat in
                    Button {
                        onSelect(cat.id)
                    } label: {
                        HStack {
                            Text(cat.name)
                            if selectedCategoryID == cat.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedCategoryName)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Category")
        }
    }
}
