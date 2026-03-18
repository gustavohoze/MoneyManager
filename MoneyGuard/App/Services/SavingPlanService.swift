import Foundation

struct SavingPlan: Equatable {
    let goalType: SavingGoalKind
    let goalTitle: String
    let targetAmount: Double
    let currentSavings: Double
    let timeframeMonths: Int
    let plannedMonthlyDeposit: Double
    let updatedAt: Date
}

struct SavingPlanDraft {
    let goalType: SavingGoalKind
    let goalTitle: String
    let targetAmount: Double
    let currentSavings: Double
    let timeframeMonths: Int
    let plannedMonthlyDeposit: Double
}

protocol SavingPlanManaging {
    func loadSavingPlan() throws -> SavingPlan
    @discardableResult
    func saveSavingPlan(_ draft: SavingPlanDraft) throws -> SavingPlan
}

struct SavingPlanService: SavingPlanManaging {
    private let repository: SavingPlanRepository

    init(repository: SavingPlanRepository) {
        self.repository = repository
    }

    func loadSavingPlan() throws -> SavingPlan {
        if let object = try repository.fetchSavingPlan(),
           let plan = map(object: object) {
            return plan
        }

        let defaultDraft = SavingPlanDraft(
            goalType: .vacation,
            goalTitle: SavingGoalKind.vacation.defaultTitle,
            targetAmount: 5000,
            currentSavings: 750,
            timeframeMonths: 12,
            plannedMonthlyDeposit: 350
        )

        return try saveSavingPlan(defaultDraft)
    }

    func saveSavingPlan(_ draft: SavingPlanDraft) throws -> SavingPlan {
        let trimmedTitle = draft.goalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTitle = trimmedTitle.isEmpty ? draft.goalType.defaultTitle : trimmedTitle
        let now = Date()

        _ = try repository.saveSavingPlan(
            goalType: draft.goalType.rawValue,
            goalTitle: normalizedTitle,
            targetAmount: max(draft.targetAmount, 1),
            currentSavings: max(draft.currentSavings, 0),
            timeframeMonths: max(draft.timeframeMonths, 1),
            plannedMonthlyDeposit: max(draft.plannedMonthlyDeposit, 0),
            updatedAt: now
        )

        return SavingPlan(
            goalType: draft.goalType,
            goalTitle: normalizedTitle,
            targetAmount: max(draft.targetAmount, 1),
            currentSavings: max(draft.currentSavings, 0),
            timeframeMonths: max(draft.timeframeMonths, 1),
            plannedMonthlyDeposit: max(draft.plannedMonthlyDeposit, 0),
            updatedAt: now
        )
    }

    private func map(object: Any) -> SavingPlan? {
        guard
            let managedObject = object as? NSObject,
            let goalTypeRaw = managedObject.value(forKey: "goalType") as? String,
            let goalType = SavingGoalKind(rawValue: goalTypeRaw),
            let goalTitle = managedObject.value(forKey: "goalTitle") as? String,
            let targetAmount = managedObject.value(forKey: "targetAmount") as? Double,
            let currentSavings = managedObject.value(forKey: "currentSavings") as? Double,
            let timeframeMonthsInt64 = managedObject.value(forKey: "timeframeMonths") as? Int64,
            let plannedMonthlyDeposit = managedObject.value(forKey: "plannedMonthlyDeposit") as? Double,
            let updatedAt = managedObject.value(forKey: "updatedAt") as? Date
        else {
            return nil
        }

        return SavingPlan(
            goalType: goalType,
            goalTitle: goalTitle,
            targetAmount: targetAmount,
            currentSavings: currentSavings,
            timeframeMonths: Int(timeframeMonthsInt64),
            plannedMonthlyDeposit: plannedMonthlyDeposit,
            updatedAt: updatedAt
        )
    }
}

struct NoOpSavingPlanService: SavingPlanManaging {
    func loadSavingPlan() throws -> SavingPlan {
        SavingPlan(
            goalType: .vacation,
            goalTitle: SavingGoalKind.vacation.defaultTitle,
            targetAmount: 5000,
            currentSavings: 750,
            timeframeMonths: 12,
            plannedMonthlyDeposit: 350,
            updatedAt: Date()
        )
    }

    func saveSavingPlan(_ draft: SavingPlanDraft) throws -> SavingPlan {
        SavingPlan(
            goalType: draft.goalType,
            goalTitle: draft.goalTitle,
            targetAmount: draft.targetAmount,
            currentSavings: draft.currentSavings,
            timeframeMonths: draft.timeframeMonths,
            plannedMonthlyDeposit: draft.plannedMonthlyDeposit,
            updatedAt: Date()
        )
    }
}
