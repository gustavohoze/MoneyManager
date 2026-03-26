import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ScannerScreen: View {
    @StateObject var viewModel: ScannerViewModel
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isPDFImporterPresented: Bool = false
    @State private var selectedPDFName: String? = nil
    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    scannerHeroCard

                    if let image = viewModel.selectedImage {
                        selectedImageCard(image)
                    }

                    if let pdfName = selectedPDFName {
                        selectedPDFCard(pdfName)
                    }

                    if viewModel.isProcessing {
                        processingCard
                    }

                    if !viewModel.parsedTransactions.isEmpty {
                        parsedTransactionsCard
                        saveButton
                    }

                    if let statusMessage = viewModel.errorMessage,
                       viewModel.parsedTransactions.isEmpty,
                       !viewModel.isProcessing {
                        statusCard(statusMessage)
                    }

                    Spacer(minLength: 20)
                }
                .padding(16)
            }
            .background(FinanceTheme.pageBackground(for: colorScheme))
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedPDFName = nil
                        viewModel.processSelectedImage(uiImage)
                    }
                }
            }
            .fileImporter(
                isPresented: $isPDFImporterPresented,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: false,
                onCompletion: handlePDFSelection
            )
            .navigationTitle("Scanner")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var scannerHeroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(palette.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan Statements")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(palette.ink)
                    Text("Import transactions from receipts or bank statements with OCR.")
                        .font(.subheadline)
                        .foregroundStyle(palette.secondaryInk)
                }
            }

            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text(viewModel.selectedImage == nil ? "Choose Image" : "Choose Another Image")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .background(palette.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                isPDFImporterPresented = true
            } label: {
                HStack {
                    Image(systemName: "doc.fill")
                    Text("Choose PDF")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(palette.ink)
                .background(palette.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .financeCard(palette: palette)
    }

    private func selectedImageCard(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Selected Image")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.ink)

                Spacer()

                Button("Clear") {
                    viewModel.selectedImage = nil
                    viewModel.parsedTransactions.removeAll()
                    viewModel.errorMessage = nil
                    selectedPDFName = nil
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.red)
            }

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .financeCard(palette: palette)
    }

    private func selectedPDFCard(_ name: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Selected PDF")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.ink)

                Spacer()

                Button("Clear") {
                    selectedPDFName = nil
                    viewModel.selectedImage = nil
                    viewModel.parsedTransactions.removeAll()
                    viewModel.errorMessage = nil
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.red)
            }

            HStack(spacing: 10) {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(palette.accent)
                Text(name)
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryInk)
                    .lineLimit(2)
                Spacer()
            }
        }
        .financeCard(palette: palette)
    }

    private var processingCard: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(palette.accent)
            Text(selectedPDFName == nil ? "Analyzing text from image..." : "Analyzing text from PDF...")
                .font(.subheadline)
                .foregroundStyle(palette.secondaryInk)
            Spacer()
        }
        .financeCard(palette: palette)
    }

    private var parsedTransactionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected Transactions")
                .font(.headline)
                .foregroundStyle(palette.ink)

            Text("Review and remove any incorrect rows before saving.")
                .font(.caption)
                .foregroundStyle(palette.secondaryInk)

            ForEach(viewModel.parsedTransactions.indices, id: \.self) { index in
                let tx = viewModel.parsedTransactions[index]

                VStack(spacing: 10) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tx.merchantRaw)
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(palette.ink)
                            Text(tx.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(palette.secondaryInk)
                        }

                        Spacer(minLength: 8)

                        Text(
                            tx.amount,
                            format: .currency(code: Locale.current.currency?.identifier ?? "USD")
                        )
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .foregroundStyle(tx.isIncome ? Color.green : palette.ink)
                    }

                    HStack {
                        Spacer()
                        Button {
                            viewModel.removeTransaction(at: index)
                        } label: {
                            Label("Remove", systemImage: "trash")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if index < viewModel.parsedTransactions.count - 1 {
                    Divider()
                        .overlay(palette.cardBorder)
                }
            }
        }
        .financeCard(palette: palette)
    }

    private var saveButton: some View {
        Button {
            viewModel.saveAllTransactions()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save All to Transactions")
                    .font(.system(.body, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(palette.accent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func statusCard(_ message: String) -> some View {
        let isSuccess = message.lowercased().contains("saved successfully")

        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isSuccess ? palette.accent : .red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(isSuccess ? palette.ink : .red)
            Spacer()
        }
        .financeCard(palette: palette)
    }

    private func handlePDFSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                viewModel.errorMessage = "No PDF selected."
                return
            }

            selectedItem = nil
            viewModel.selectedImage = nil
            selectedPDFName = url.lastPathComponent

            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("scanner-")
                    .appendingPathExtension(UUID().uuidString)
                    .appendingPathExtension("pdf")
                try? FileManager.default.removeItem(at: tempURL)
                try FileManager.default.copyItem(at: url, to: tempURL)
                viewModel.processSelectedPDF(tempURL)
            } catch {
                viewModel.errorMessage = "Failed to open PDF: \(error.localizedDescription)"
            }
        case .failure(let error):
            viewModel.errorMessage = "PDF selection failed: \(error.localizedDescription)"
        }
    }
}
