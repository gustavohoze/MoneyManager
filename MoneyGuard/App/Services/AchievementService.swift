import Foundation
import Combine

class AchievementService: ObservableObject {
    @Published private(set) var earnedAchievementIds: Set<String> = []
    @Published var selectedAchievementId: String? {
        didSet {
            if let id = selectedAchievementId {
                userDefaults.set(id, forKey: selectedAchievementKey)
            } else {
                userDefaults.removeObject(forKey: selectedAchievementKey)
            }
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let achievementsKey = "achievements.earned"
    private let selectedAchievementKey = "achievements.selected"
    
    init() {
        loadEarnedAchievements()
        loadSelectedAchievement()
    }
    
    private func loadEarnedAchievements() {
        guard let data = userDefaults.string(forKey: achievementsKey), !data.isEmpty else {
            earnedAchievementIds = []
            return
        }
        let ids = data.split(separator: ",").map { String($0) }
        earnedAchievementIds = Set(ids)
    }

    private func loadSelectedAchievement() {
        selectedAchievementId = userDefaults.string(forKey: selectedAchievementKey)
    }
    
    func getEarnedAchievements() -> [Achievement] {
        let earned = earnedAchievementIds
        return AchievementType.allAchievements.map { template in
            if earned.contains(template.id) {
                return Achievement(
                    id: template.id,
                    title: template.title,
                    description: template.description,
                    icon: template.icon,
                    isEarned: true,
                    earnedDate: Date(),
                    redeemCode: nil
                )
            }
            return template
        }
    }
    
    func unlockAchievement(id: String) {
        var earned = earnedAchievementIds
        guard !earned.contains(id) else { return }
        
        earned.insert(id)
        earnedAchievementIds = earned
        userDefaults.set(earned.sorted().joined(separator: ","), forKey: achievementsKey)
        
        // Auto-select first earned achievement if none selected
        if selectedAchievementId == nil {
            selectedAchievementId = id
        }
    }
    
    func getSelectedAchievement() -> Achievement? {
        guard let selectedId = selectedAchievementId, earnedAchievementIds.contains(selectedId) else {
            return nil
        }
        return getEarnedAchievements().first { $0.id == selectedId && $0.isEarned }
    }
    
    func isAchievementEarned(id: String) -> Bool {
        earnedAchievementIds.contains(id)
    }
}
