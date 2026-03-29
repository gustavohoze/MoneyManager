import SwiftUI
import UniformTypeIdentifiers

struct SettingsDataSyncPrivacyDetailPage: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject private var persistenceStoreManager: PersistenceStoreManager
    @Environment(\.colorScheme) private var colorScheme
    let palette: FinanceTheme.Palette

    @State private var iCloudStatus = String(localized: "Not checked yet")
    @State private var isCheckingICloud = false
    @State private var actionFeedback = ""
    @State private var isImportFilePickerPresented = false
    @State private var isExportFilePickerPresented = false
    @State private var exportDocument: ExportFileDocument?
    @State private var exportFilename = "transactions"
    @State private var exportContentType: UTType = .json

    @AppStorage("settings.lockWithFaceID") private var lockWithFaceID = false
    @AppStorage("settings.hideBalances") private var hideBalances = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // iCloud Sync section header
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "iCloud Sync"))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .textCase(.uppercase)
                    Text(String(localized: "Cloud Storage"))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // iCloud status card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "icloud.and.arrow.up.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(palette.accent)
                            .frame(width: 32, height: 32)
                            .background(palette.accentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "iCloud Sync Status"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(palette.ink)
                            Text(iCloudStatus)
                                .font(.caption)
                                .foregroundStyle(palette.secondaryInk)
                        }

                        Spacer()

                        if isCheckingICloud {
                            ProgressView()
                        }
                    }

                    Divider()
                        .padding(.vertical, 4)

                    Button {
                        Task {
                            await checkICloudAvailability()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text(String(localized: "Check Availability"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(palette.accent)
                    }

                    Button {
                        actionFeedback = persistenceStoreManager.requestCloudKitUpgrade().message
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text(String(localized: "Retry CloudKit Store"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(palette.accent)
                    }

                    if persistenceStoreManager.requiresAppRestartForCloudKitUpgrade {
                        Text(String(localized: "CloudKit upgrade will be applied on next app launch."))
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    if !actionFeedback.isEmpty {
                        Text(actionFeedback)
                            .font(.footnote)
                            .foregroundStyle(palette.secondaryInk)
                    }
                }
                .financeCard(palette: palette)

                Text(String(localized: "Active store mode: \(persistenceStoreManager.controller.activeStoreMode.rawValue)"))
                    .font(.caption)
                    .foregroundStyle(palette.secondaryInk)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let error = persistenceStoreManager.controller.storeLoadErrorDescription,
                   !error.isEmpty {
                    Text(String(localized: "Last store error: \(error)"))
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()
                    .padding(.vertical, 4)

                // Privacy section header
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Privacy & Security"))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .textCase(.uppercase)
                    Text(String(localized: "Protect Your Data"))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Face ID toggle
                SettingsSecurityCard(
                    icon: "faceid",
                    title: String(localized: "Lock with Face ID"),
                    description: String(localized: "Require Face ID to access the app"),
                    isEnabled: $lockWithFaceID,
                    palette: palette
                )

                // Hide balances toggle
                SettingsSecurityCard(
                    icon: "eye.slash.fill",
                    title: String(localized: "Hide Balances by Default"),
                    description: String(localized: "Tap to reveal payment method balances"),
                    isEnabled: $hideBalances,
                    palette: palette
                )

                // Info card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(palette.accent)
                        Text(String(localized: "Privacy settings help keep your financial data secure."))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryInk)
                    }
                }
                .financeCard(palette: palette)

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
                    Button {
                        if let jsonData = viewModel.exportTransactionsAsJSON() {
                            exportDocument = ExportFileDocument(data: jsonData)
                            exportFilename = "transactions_\(timestampString())"
                            exportContentType = .json
                            isExportFilePickerPresented = true
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

                    Button {
                        if let csvData = viewModel.exportTransactionsAsCSV() {
                            exportDocument = ExportFileDocument(data: csvData)
                            exportFilename = "transactions_\(timestampString())"
                            exportContentType = .commaSeparatedText
                            isExportFilePickerPresented = true
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
                        allowedContentTypes: [.json, .commaSeparatedText, .plainText, .data],
                        allowsMultipleSelection: false
                    ) { result in
                        handleImport(result: result)
                    }
                }
                .financeCard(palette: palette)
            }
            .padding(16)
        }
        .background(FinanceTheme.pageBackground(for: colorScheme))
        .navigationTitle(String(localized: "Privacy & Security"))
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $isExportFilePickerPresented,
            document: exportDocument,
            contentType: exportContentType,
            defaultFilename: exportFilename
        ) { result in
            switch result {
            case .success:
                let successMessage = exportContentType == .json
                    ? String(localized: "JSON export saved.")
                    : String(localized: "CSV export saved.")
                viewModel.presentToast(message: successMessage)
            case .failure(let error):
                viewModel.presentToast(message: error.localizedDescription, isError: true)
            }
        }
    }

    private func checkICloudAvailability() async {
        isCheckingICloud = true
        defer { isCheckingICloud = false }
        let result = await ICloudAvailabilityService().checkAvailability()
        iCloudStatus = result.message
    }

    private func handleImport(result: Result<[URL], Error>) {
        guard case let .success(urls) = result,
              let fileURL = urls.first else {
            return
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            viewModel.presentToast(message: String(localized: "Unable to read selected file."), isError: true)
            return
        }

        let filename = fileURL.lastPathComponent.lowercased()
        if filename.hasSuffix(".json") {
            viewModel.importTransactions(from: data, format: "json")
        } else if filename.hasSuffix(".csv") {
            viewModel.importTransactions(from: data, format: "csv")
        } else {
            viewModel.presentToast(message: String(localized: "Unsupported file format. Please choose .json or .csv."), isError: true)
        }
    }

    private func timestampString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}

private struct ExportFileDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.json, .commaSeparatedText, .plainText]
    }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct SettingsSecurityCard: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(palette.accent)
                    .frame(width: 32, height: 32)
                    .background(palette.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(palette.secondaryInk)
                }

                Spacer()

                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
            }
        }
        .padding(14)
        .background(palette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.cardBorder, lineWidth: 1)
        )
    }
}


