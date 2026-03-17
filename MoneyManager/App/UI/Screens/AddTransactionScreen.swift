import SwiftUI

struct AddTransactionScreen: View {
    private enum TutorialPhase {
        case tapAmount
        case merchant
        case details
        case metadata
        case save
    }

    @ObservedObject var viewModel: AddTransactionViewModel
    var autoFocusAmountOnAppear: Bool = false
    @FocusState private var focusedField: AddTransactionFormField?
    @Environment(\.colorScheme) private var colorScheme
    @State private var tutorialPhase: TutorialPhase?
    @State private var didInitializeFirstExpenseGuide = false

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    private var isFirstExpenseGuideActive: Bool {
        tutorialPhase != nil
    }

    private var isHighlightingAmount: Bool {
        tutorialPhase == .tapAmount
    }

    private var isHighlightingSaveButton: Bool {
        tutorialPhase == .save
    }

    private var isHighlightingMerchant: Bool {
        tutorialPhase == .merchant
    }

    private var isHighlightingDetails: Bool {
        tutorialPhase == .details
    }

    private var isHighlightingMetadata: Bool {
        tutorialPhase == .metadata
    }

    private var orderedTutorialPhases: [TutorialPhase] {
        var phases: [TutorialPhase] = [.tapAmount, .merchant]
        if viewModel.shouldShowDetailsSection {
            phases.append(.details)
        }
        phases.append(.metadata)
        phases.append(.save)
        return phases
    }

    private var tutorialCurrentStep: Int {
        guard let tutorialPhase,
              let index = orderedTutorialPhases.firstIndex(of: tutorialPhase)
        else { return 0 }

        return index + 1
    }

    private var tutorialTotalSteps: Int {
        orderedTutorialPhases.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FinanceTheme.pageBackground(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Hero amount card
                        AddTransactionAmountHeroCard(
                            amountText: $viewModel.amountText,
                            currencyCode: viewModel.currency,
                            fontSize: viewModel.amountFieldFontSize,
                            focusedField: $focusedField,
                            palette: palette,
                            onAmountChange: viewModel.didChangeAmountText
                        )
                        .overlay {
                            if isHighlightingAmount {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(palette.accent, lineWidth: 2)
                            }
                        }
                        .shadow(color: isHighlightingAmount ? palette.accent.opacity(0.40) : .clear, radius: 18)
                        .zIndex(isHighlightingAmount ? 2 : 0)
                        .tutorialDimmed(isFirstExpenseGuideActive && !isHighlightingAmount)
                        .allowsHitTesting(!isFirstExpenseGuideActive)

                        if tutorialPhase == .tapAmount,
                           let tutorialInstructionText {
                            tutorialInstructionCard(text: tutorialInstructionText)
                        }

                        // Merchant section
                        AddTransactionSectionLabel(text: String(localized: "Merchant"), palette: palette)
                            .tutorialDimmed(isFirstExpenseGuideActive && !isHighlightingMerchant)

                        AddTransactionMerchantInputCard(
                            merchantText: $viewModel.merchantRaw,
                            suggestions: viewModel.merchantSuggestions,
                            palette: palette,
                            onMerchantChange: viewModel.updateMerchantSuggestions,
                            onSelectSuggestion: viewModel.selectMerchantSuggestion
                        )
                        .tutorialDimmed(isFirstExpenseGuideActive && !isHighlightingMerchant)
                        .allowsHitTesting(!isFirstExpenseGuideActive)

                        if tutorialPhase == .merchant,
                           let tutorialInstructionText {
                            tutorialInstructionCard(text: tutorialInstructionText)
                        }

                        // Details section (Category & Account)
                        if viewModel.shouldShowDetailsSection {
                            AddTransactionSectionLabel(text: String(localized: "Details"), palette: palette)
                                .tutorialDimmed(isFirstExpenseGuideActive && !isHighlightingDetails)

                            HStack(spacing: 12) {
                                if !viewModel.categoryOptions.isEmpty {
                                    AddTransactionCategoryPickerCard(
                                        selectedCategory: viewModel.selectedCategoryOption,
                                        categories: viewModel.categoryOptions,
                                        palette: palette,
                                        onSelect: { viewModel.selectedCategoryID = $0 }
                                    )
                                }

                                if !viewModel.accountOptions.isEmpty {
                                    AddTransactionAccountPickerCard(
                                        selectedAccount: viewModel.selectedAccountOption,
                                        accounts: viewModel.accountOptions,
                                        palette: palette,
                                        onSelect: { viewModel.selectedAccountID = $0 }
                                    )
                                }
                            }
                            .tutorialDimmed(isFirstExpenseGuideActive && !isHighlightingDetails)
                            .allowsHitTesting(!isFirstExpenseGuideActive)

                            if tutorialPhase == .details,
                               let tutorialInstructionText {
                                tutorialInstructionCard(text: tutorialInstructionText)
                            }
                        }

                        // Metadata section (Date & Note)
                        AddTransactionSectionLabel(text: String(localized: "Transaction Info"), palette: palette)
                            .tutorialDimmed(isFirstExpenseGuideActive && !isHighlightingMetadata)

                        AddTransactionMetadataCard(
                            selectedDate: $viewModel.selectedDate,
                            note: $viewModel.note,
                            palette: palette
                        )
                        .tutorialDimmed(isFirstExpenseGuideActive && !isHighlightingMetadata)
                        .allowsHitTesting(!isFirstExpenseGuideActive)

                        if tutorialPhase == .metadata,
                           let tutorialInstructionText {
                            tutorialInstructionCard(text: tutorialInstructionText)
                        }

                        // Error display
                        if viewModel.shouldShowErrorSection,
                           let error = viewModel.error {
                            AddTransactionErrorCard(
                                error: error,
                                errorMessage: viewModel.errorMessage(for: error),
                                palette: palette
                            )
                            .tutorialDimmed(isFirstExpenseGuideActive)
                        }

                        // Save button
                        AddTransactionSaveButtonCard(
                            isSaving: viewModel.isSaving,
                            isEnabled: viewModel.canSaveForm && !isFirstExpenseGuideActive,
                            palette: palette,
                            onSave: {
                                focusedField = nil
                                viewModel.saveFromForm()
                            }
                        )
                        .overlay {
                            if isHighlightingSaveButton {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(palette.accent, lineWidth: 2)
                            }
                        }
                        .shadow(color: isHighlightingSaveButton ? palette.accent.opacity(0.40) : .clear, radius: 16)
                        .tutorialDimmed(isFirstExpenseGuideActive && !isHighlightingSaveButton)
                        .allowsHitTesting(!isFirstExpenseGuideActive)

                        if tutorialPhase == .save,
                           let tutorialInstructionText {
                            tutorialInstructionCard(text: tutorialInstructionText)
                        }

                        if let saveMessage = viewModel.saveMessage {
                            AddTransactionUndoRow(
                                message: saveMessage,
                                canUndo: viewModel.canUndoLastSave,
                                duplicateWarning: viewModel.duplicateWarning,
                                onUndo: {
                                    focusedField = nil
                                    viewModel.undoLastSave()
                                }
                            )
                            .padding(.top, 4)
                            .tutorialDimmed(isFirstExpenseGuideActive)
                            .allowsHitTesting(!isFirstExpenseGuideActive)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(16)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if isFirstExpenseGuideActive {
                        moveToNextTutorialStep()
                    } else {
                        focusedField = nil
                    }
                }
            }
            .navigationTitle(String(localized: "New Transaction"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(isFirstExpenseGuideActive ? .hidden : .visible, for: .tabBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "Done")) {
                        focusedField = nil
                    }
                }
            }
            .onAppear {
                viewModel.loadOptions()

                if autoFocusAmountOnAppear,
                   !didInitializeFirstExpenseGuide {
                    didInitializeFirstExpenseGuide = true
                    tutorialPhase = orderedTutorialPhases.first
                }
            }
        }
    }

    private var tutorialInstructionText: String? {
        switch tutorialPhase {
        case .tapAmount:
            return String(localized: "Amount: this is where you enter how much you spent.")
        case .merchant:
            return String(localized: "Merchant: add where you spent money so your history is clearer.")
        case .details:
            return String(localized: "Details: choose category and payment method for better tracking.")
        case .metadata:
            return String(localized: "Transaction Info: set date and optional note for context.")
        case .save:
            return String(localized: "Save: when you are ready, tap here to store the expense.")
        case .none:
            return nil
        }
    }

    private func tutorialInstructionCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(palette.accent)
                    Text(String(localized: "Guided First Expense"))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)
                }

                Spacer(minLength: 8)

                Text(String(localized: "Step \(tutorialCurrentStep) of \(tutorialTotalSteps)"))
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.secondaryInk)
            }

            Text(text)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(palette.secondaryInk)

            Text(String(localized: "Tap anywhere to continue"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.secondaryInk)

            Button(String(localized: "Skip tutorial")) {
                skipTutorial()
            }
            .buttonStyle(.plain)
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(palette.accent)
            )
        }
        .financeCard(palette: palette)
    }

    private func moveToNextTutorialStep() {
        guard let tutorialPhase,
              let currentIndex = orderedTutorialPhases.firstIndex(of: tutorialPhase)
        else {
            skipTutorial()
            return
        }

        let nextIndex = currentIndex + 1
        if nextIndex < orderedTutorialPhases.count {
            self.tutorialPhase = orderedTutorialPhases[nextIndex]
        } else {
            skipTutorial()
        }
    }

    private func skipTutorial() {
        focusedField = nil
        tutorialPhase = nil
    }
}

private struct TutorialDimModifier: ViewModifier {
    let isDimmed: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isDimmed ? 0.32 : 1)
            .animation(.easeOut(duration: 0.2), value: isDimmed)
    }
}

private extension View {
    func tutorialDimmed(_ isDimmed: Bool) -> some View {
        modifier(TutorialDimModifier(isDimmed: isDimmed))
    }
}

// MARK: - Preview

#Preview {
    AddTransactionScreen(viewModel: .previewInstance)
}
