import SwiftUI

struct AccountEditorSheet: View {
    @Binding var draft: AccountEditorDraft

    let paymentMethodTypeOptions: [String]
    let onCancel: () -> Void
    let onSave: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "Name"))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.secondaryInk)

                        TextField(String(localized: "Payment Method Name"), text: $draft.name)
                            .textFieldStyle(.plain)
                    }
                    .financeCard(palette: palette)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "Type"))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.secondaryInk)

                        Picker(String(localized: "Payment Method Type"), selection: $draft.type) {
                            ForEach(paymentMethodTypeOptions, id: \.self) { type in
                                Text(type.capitalized).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .financeCard(palette: palette)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "Currency is controlled by Display Currency in Settings."))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryInk)
                    }
                    .financeCard(palette: palette)
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(FinanceTheme.pageBackground(for: colorScheme).ignoresSafeArea())
            .navigationTitle(draft.paymentMethodID == nil ? String(localized: "Add Payment Method") : String(localized: "Edit Payment Method"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel"), action: onCancel)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Save"), action: onSave)
                }
            }
        }
    }
}
