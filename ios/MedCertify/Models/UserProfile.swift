import SwiftData
import Foundation

@Model
class UserProfile {
    var id: UUID
    var profession: String
    var name: String
    var npiNumber: String?
    var selectedStates: [String]
    var selectedCredentialTypes: [String]
    var earliestRenewalDate: Date?
    var currentTrackingMethod: String?
    var onboardingComplete: Bool
    var isPro: Bool
    var createdAt: Date

    init(
        profession: String = "",
        name: String = "",
        npiNumber: String? = nil,
        selectedStates: [String] = [],
        selectedCredentialTypes: [String] = [],
        earliestRenewalDate: Date? = nil,
        currentTrackingMethod: String? = nil,
        onboardingComplete: Bool = false,
        isPro: Bool = false
    ) {
        self.id = UUID()
        self.profession = profession
        self.name = name
        self.npiNumber = npiNumber
        self.selectedStates = selectedStates
        self.selectedCredentialTypes = selectedCredentialTypes
        self.earliestRenewalDate = earliestRenewalDate
        self.currentTrackingMethod = currentTrackingMethod
        self.onboardingComplete = onboardingComplete
        self.isPro = isPro
        self.createdAt = Date()
    }
}
