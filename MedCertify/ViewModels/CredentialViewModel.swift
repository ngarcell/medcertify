import SwiftUI
import SwiftData

@Observable
class CredentialViewModel {
    private let modelContext: ModelContext

    var searchText: String = ""

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func addCredential(_ credential: Credential) {
        let defaultChecklist = [
            "CME hours completed",
            "Renewal application submitted",
            "Fee paid",
            "New certificate received"
        ]
        for item in defaultChecklist {
            let checklistItem = ChecklistItem(title: item)
            credential.checklistItems.append(checklistItem)
        }
        modelContext.insert(credential)
    }

    func deleteCredential(_ credential: Credential) {
        modelContext.delete(credential)
    }

    func renewCredential(_ credential: Credential) {
        let history = RenewalHistory(
            renewalDate: Date(),
            previousExpiration: credential.expirationDate,
            newExpiration: Calendar.current.date(
                byAdding: .month,
                value: credential.renewalCycleMonths,
                to: credential.expirationDate ?? Date()
            )
        )
        credential.renewalHistories.append(history)

        credential.expirationDate = Calendar.current.date(
            byAdding: .month,
            value: credential.renewalCycleMonths,
            to: credential.expirationDate ?? Date()
        )

        for item in credential.checklistItems {
            item.completed = false
            item.completedAt = nil
        }
    }

    func fetchCredentials() -> [Credential] {
        let descriptor = FetchDescriptor<Credential>(
            sortBy: [SortDescriptor(\.expirationDate)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func credentialsByCategory(_ credentials: [Credential]) -> [(String, [Credential])] {
        let grouped = Dictionary(grouping: credentials) { $0.credentialType.category }
        return grouped.sorted { $0.key < $1.key }
    }

    func upcomingRenewals(_ credentials: [Credential]) -> [Credential] {
        credentials
            .filter { $0.status == .expiringSoon || $0.status == .expired }
            .sorted { ($0.daysUntilExpiration ?? Int.max) < ($1.daysUntilExpiration ?? Int.max) }
    }

    func healthScore(_ credentials: [Credential]) -> HealthScore {
        guard !credentials.isEmpty else { return .good }
        let hasExpired = credentials.contains { $0.status == .expired }
        let hasExpiring = credentials.contains { $0.status == .expiringSoon }
        if hasExpired { return .critical }
        if hasExpiring { return .attention }
        return .good
    }
}

nonisolated enum HealthScore: Sendable {
    case good, attention, critical

    var title: String {
        switch self {
        case .good: return "All Current"
        case .attention: return "Attention Needed"
        case .critical: return "Action Required"
        }
    }

    var icon: String {
        switch self {
        case .good: return "checkmark.shield.fill"
        case .attention: return "exclamationmark.shield.fill"
        case .critical: return "xmark.shield.fill"
        }
    }
}
