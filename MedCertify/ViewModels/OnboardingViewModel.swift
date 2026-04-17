import SwiftUI
import SwiftData

@Observable
class OnboardingViewModel {
    var currentPage: Int = 0
    var profession: String = ""
    var selectedStates: Set<String> = []
    var selectedCredentialTypes: Set<String> = []
    var notificationsEnabled: Bool = false

    let totalPages = 7

    func saveProfile(modelContext: ModelContext) {
        let profile = UserProfile(
            profession: profession,
            selectedStates: Array(selectedStates),
            selectedCredentialTypes: Array(selectedCredentialTypes),
            earliestRenewalDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date(),
            currentTrackingMethod: "",
            onboardingComplete: true
        )
        modelContext.insert(profile)
    }

    func nextPage() {
        if currentPage < totalPages - 1 {
            withAnimation(.spring(duration: 0.4)) {
                currentPage += 1
            }
        }
    }

    func previousPage() {
        if currentPage > 0 {
            withAnimation(.spring(duration: 0.4)) {
                currentPage -= 1
            }
        }
    }
}
