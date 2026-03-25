import SwiftUI
import SwiftData

@Observable
class CMEViewModel {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func addActivity(_ activity: CMEActivity) {
        modelContext.insert(activity)
    }

    func deleteActivity(_ activity: CMEActivity) {
        modelContext.delete(activity)
    }

    func fetchActivities() -> [CMEActivity] {
        let descriptor = FetchDescriptor<CMEActivity>(
            sortBy: [SortDescriptor(\.dateCompleted, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func totalHours(_ activities: [CMEActivity]) -> Double {
        activities.reduce(0) { $0 + $1.hours }
    }

    func hoursByType(_ activities: [CMEActivity]) -> [(String, Double)] {
        let grouped = Dictionary(grouping: activities) { $0.creditType }
        return grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.hours }) }
            .sorted { $0.1 > $1.1 }
    }

    func activitiesForCycle(_ activities: [CMEActivity], cycle: CMECycle) -> [CMEActivity] {
        activities.filter { $0.dateCompleted >= cycle.startDate && $0.dateCompleted <= cycle.endDate }
    }

    func addCycle(_ cycle: CMECycle) {
        modelContext.insert(cycle)
    }

    func fetchCycles() -> [CMECycle] {
        let descriptor = FetchDescriptor<CMECycle>(
            sortBy: [SortDescriptor(\.endDate)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
