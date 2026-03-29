import SwiftUI
import UniformTypeIdentifiers

struct SettingsAdvancedDetailPage: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.colorScheme) private var colorScheme
    let palette: FinanceTheme.Palette

    @AppStorage("debug.showMilestoneZeroExamples") private var showMilestoneZeroExamples = false
    @State private var isDeleteConfirmationPresented = false
    @State private var isImportFilePickerPresented = false
    @State private var importFileType: String = "json"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Testing section
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Testing"))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .textCase(.uppercase)
                    Text(String(localized: "Sample Data"))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Create dummy transactions
                Button {
                    viewModel.createDummyTransactions()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(palette.accent)
                            .frame(width: 32, height: 32)
                            .background(palette.accentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Create Dummy Transactions"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(palette.ink)
                            Text(String(localized: "Add sample data for testing"))
                                .font(.caption)
                                .foregroundStyle(palette.secondaryInk)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(palette.secondaryInk)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .financeCard(palette: palette)
                }

                // Delete dummy transactions
                Button(role: .destructive) {
                    isDeleteConfirmationPresented = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.red)
                            .frame(width: 32, height: 32)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Delete Dummy Transactions"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(.red)
                            Text(String(localized: "Remove all sample data"))
                                .font(.caption)
                                .foregroundStyle(palette.secondaryInk)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(palette.secondaryInk)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.red.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
                }
                .confirmationDialog(
                    String(localized: "Delete All Dummy Transactions?"),
                    isPresented: $isDeleteConfirmationPresented,
                    actions: {
                        Button(String(localized: "Delete"), role: .destructive) {
                            viewModel.deleteDummyTransactions()
                        }
                        Button(String(localized: "Cancel"), role: .cancel) {}
                    },
                    message: {
                        Text(String(localized: "This will remove all sample transactions. This action cannot be undone."))
                    }
                )

                Divider()
                    .padding(.vertical, 4)

                // Data Import/Export section
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Data"))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .textCase(.uppercase)
                    Text(String(localized: "Import & Export"))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    // Export as JSON
                    Button {
                        let fileName = "transactions_\(ISO8601DateFormatter().string(from: Date())).json"
                        if let jsonData = viewModel.exportTransactionsAsJSON() {
                            exportFile(data: jsonData, filename: fileName)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.up.doc.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(palette.accent)
                                .frame(width: 32, height: 32)
                                .background(palette.accentSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "Export as JSON"))
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .foregroundStyle(palette.ink)
                                Text(String(localized: "Export all transactions in JSON format"))
                                    .font(.caption)
                                    .foregroundStyle(palette.secondaryInk)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(palette.secondaryInk)
                        }
                    }

                    // Export as CSV
                    Button {
                        let fileName = "transactions_\(ISO8601DateFormatter().string(from: Date())).csv"
                        if let csvData = viewModel.exportTransactionsAsCSV() {
                            exportFile(data: csvData, filename: fileName)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.up.doc.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(palette.accent)
                                .frame(width: 32, height: 32)
                                .background(palette.accentSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "Export as CSV"))
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .foregroundStyle(palette.ink)
                                Text(String(localized: "Export all transactions in CSV format"))
                                    .font(.caption)
                                    .foregroundStyle(palette.secondaryInk)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(palette.secondaryInk)
                        }
                    }

                    // Import transactions
                    Button {
                        isImportFilePickerPresented = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(palette.accent)
                                .frame(width: 32, height: 32)
                                .background(palette.accentSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "Import Transactions"))
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .foregroundStyle(palette.ink)
                                Text(String(localized: "Import from JSON or CSV file"))
                                    .font(.caption)
                                    .foregroundStyle(palette.secondaryInk)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(palette.secondaryInk)
                        }
                    }
                    .fileImporter(
                        isPresented: $isImportFilePickerPresented,
                        allowedContentTypes: [.json, .data],
                        allowsMultipleSelection: false
                    ) { result in
                        handleImport(result: result)
                    }
                }
                .financeCard(palette: palette)

                Divider()
                    .padding(.vertical, 4)

                // Debug section
#if DEBUG
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Debug"))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .textCase(.uppercase)
                    Text(String(localized: "Development Options"))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "flask.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(palette.accent)
                            .frame(width: 32, height: 32)
                            .background(palette.accentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Show Milestone 0 Examples"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(palette.ink)
                            Text(String(localized: "Display example UI components"))
                                .font(.caption)
                                .foregroundStyle(palette.secondaryInk)
                        }

                        Spacer()

                        Toggle("", isOn: $showMilestoneZeroExamples)
                            .labelsHidden()
                    }
                }
                .financeCard(palette: palette)
#endif

                // Info card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(palette.accent)
                        Text(String(localized: "Advanced features are for developers and testing purposes only."))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryInk)
                    }
                }
                .financeCard(palette: palette)
            }
            .padding(16)
        }
        .background(FinanceTheme.pageBackground(for: colorScheme))
        .navigationTitle(String(localized: "Advanced"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helper Methods

    private func exportFile(data: Data, filename: String) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
        } catch {
            // Error is handled by the toast in the viewModel
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let fileURL = urls.first else { return }

            do {
                let data = try Data(contentsOf: fileURL)
                let filename = fileURL.lastPathComponent.lowercased()

                if filename.hasSuffix(".json") {
                    viewModel.importTransactions(from: data, format: "json")
                } else if filename.hasSuffix(".csv") {
                    viewModel.importTransactions(from: data, format: "csv")
                } else {
                    // Toast will be shown by viewModel
                }
            } catch {
                // Toast will be shown by viewModel
            }

        case .failure:
            // Toast will be shown by viewModel
            break
        }
    }
}


