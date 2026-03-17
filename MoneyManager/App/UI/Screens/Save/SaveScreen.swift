import SwiftUI

struct SaveScreen: View {
    @ObservedObject var viewModel: SavePlanningViewModel
    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroCard
                    goalTypeCard
                    planningInputsCard
                    projectionCard
                }
                .padding(16)
            }
            .background(FinanceTheme.pageBackground(for: colorScheme))
            .navigationTitle(String(localized: "Save"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Save Plan")) {
                        viewModel.save()
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .onAppear {
                viewModel.load()
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Plan Your Savings"))
                .font(.title2.weight(.bold))
                .foregroundStyle(palette.ink)

            Text(String(localized: "Set a target for a vacation, a purchase, or any personal goal and track your monthly plan."))
                .font(.subheadline)
                .foregroundStyle(palette.secondaryInk)

            ProgressView(value: viewModel.progressRatio)
                .tint(palette.accent)

            HStack {
                Text(currency(viewModel.currentSavings))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.ink)

                Spacer()

                Text(String(localized: "of \(currency(viewModel.targetAmount))"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(palette.secondaryInk)
            }

            if let lastSavedAt = viewModel.lastSavedAt {
                Text(String(localized: "Last saved") + ": " + lastSavedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(palette.secondaryInk)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .financeCard(palette: palette)
    }

    private var goalTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Goal"))
                .font(.headline)
                .foregroundStyle(palette.ink)

            TextField(String(localized: "Goal name"), text: $viewModel.goalTitle)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                ForEach(SavingGoalKind.allCases) { kind in
                    Button {
                        viewModel.selectGoal(kind)
                    } label: {
                        Text(kind.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(viewModel.selectedGoal == kind ? Color.white : palette.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(viewModel.selectedGoal == kind ? palette.accent : palette.accentSoft)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .financeCard(palette: palette)
    }

    private var planningInputsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "Saving Plan"))
                .font(.headline)
                .foregroundStyle(palette.ink)

            sliderRow(
                title: String(localized: "Target Amount"),
                valueLabel: currency(viewModel.targetAmount),
                value: $viewModel.targetAmount,
                range: 100...50000,
                step: 100
            )

            sliderRow(
                title: String(localized: "Already Saved"),
                valueLabel: currency(viewModel.currentSavings),
                value: $viewModel.currentSavings,
                range: 0...viewModel.targetAmount,
                step: 50
            )

            sliderRow(
                title: String(localized: "Timeframe"),
                valueLabel: "\(viewModel.timeframeMonths) \(String(localized: "months"))",
                value: timeframeBinding,
                range: 1...48,
                step: 1
            )

            sliderRow(
                title: String(localized: "Planned Monthly Deposit"),
                valueLabel: currency(viewModel.plannedMonthlyDeposit),
                value: $viewModel.plannedMonthlyDeposit,
                range: 0...5000,
                step: 25
            )
        }
        .financeCard(palette: palette)
    }

    private var projectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Projection"))
                .font(.headline)
                .foregroundStyle(palette.ink)

            projectionRow(title: String(localized: "Recommended monthly"), value: currency(viewModel.recommendedMonthlyDeposit))
            projectionRow(title: String(localized: "Projected total"), value: currency(viewModel.projectedTotal))
            projectionRow(
                title: String(localized: "Remaining gap"),
                value: viewModel.projectedGap == 0 ? String(localized: "Goal reached") : currency(viewModel.projectedGap),
                valueColor: viewModel.projectedGap == 0 ? palette.accent : palette.ink
            )
        }
        .financeCard(palette: palette)
    }

    private var timeframeBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.timeframeMonths) },
            set: { viewModel.timeframeMonths = max(Int($0.rounded()), 1) }
        )
    }

    private func sliderRow(
        title: String,
        valueLabel: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.ink)

                Spacer()

                Text(valueLabel)
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryInk)
            }

            Slider(value: value, in: range, step: step)
                .tint(palette.accent)
        }
    }

    private func projectionRow(title: String, value: String, valueColor: Color? = nil) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(palette.secondaryInk)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(valueColor ?? palette.ink)
        }
        .font(.subheadline)
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}

#Preview {
    SaveScreen(viewModel: SavePlanningViewModel(planManager: NoOpSavingPlanService()))
}
