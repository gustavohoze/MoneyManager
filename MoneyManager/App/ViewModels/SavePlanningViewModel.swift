import Foundation
import Combine

@MainActor
final class SavePlanningViewModel: ObservableObject {
    @Published var selectedGoal: SavingGoalKind = .vacation
    @Published var goalTitle: String = SavingGoalKind.vacation.defaultTitle
    @Published var targetAmount: Double = 5000
    @Published var currentSavings: Double = 750
    @Published var timeframeMonths: Int = 12
    @Published var plannedMonthlyDeposit: Double = 350

    @Published private(set) var isSaving: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastSavedAt: Date?

    private let planManager: SavingPlanManaging

    init(planManager: SavingPlanManaging) {
        self.planManager = planManager
    }

    var remainingAmount: Double {
        max(targetAmount - currentSavings, 0)
    }

    var recommendedMonthlyDeposit: Double {
        remainingAmount / Double(max(timeframeMonths, 1))
    }

    var projectedTotal: Double {
        currentSavings + (plannedMonthlyDeposit * Double(timeframeMonths))
    }

    var projectedGap: Double {
        max(targetAmount - projectedTotal, 0)
    }

    var progressRatio: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentSavings / targetAmount, 1)
    }

    func load() {
        do {
            let plan = try planManager.loadSavingPlan()
            selectedGoal = plan.goalType
            goalTitle = plan.goalTitle
            targetAmount = plan.targetAmount
            currentSavings = plan.currentSavings
            timeframeMonths = max(plan.timeframeMonths, 1)
            plannedMonthlyDeposit = plan.plannedMonthlyDeposit
            lastSavedAt = plan.updatedAt
            errorMessage = nil
        } catch {
            errorMessage = String(localized: "Could not load saving plan")
        }
    }

    func save() {
        guard !isSaving else {
            return
        }

        isSaving = true
        defer { isSaving = false }

        let draft = SavingPlanDraft(
            goalType: selectedGoal,
            goalTitle: goalTitle,
            targetAmount: targetAmount,
            currentSavings: currentSavings,
            timeframeMonths: max(timeframeMonths, 1),
            plannedMonthlyDeposit: plannedMonthlyDeposit
        )

        do {
            let plan = try planManager.saveSavingPlan(draft)
            selectedGoal = plan.goalType
            goalTitle = plan.goalTitle
            targetAmount = plan.targetAmount
            currentSavings = plan.currentSavings
            timeframeMonths = plan.timeframeMonths
            plannedMonthlyDeposit = plan.plannedMonthlyDeposit
            lastSavedAt = plan.updatedAt
            errorMessage = nil
        } catch {
            errorMessage = String(localized: "Could not save to iCloud")
        }
    }

    func selectGoal(_ goal: SavingGoalKind) {
        selectedGoal = goal
        goalTitle = goal.defaultTitle
    }
}
