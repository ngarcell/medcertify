import SwiftData
import Foundation

nonisolated enum CMECreditType: String, Codable, CaseIterable, Sendable {
    case amaPRA1 = "AMA PRA Category 1"
    case amaPRA2 = "AMA PRA Category 2"
    case aafp = "AAFP Prescribed"
    case ancc = "ANCC"
    case acpe = "ACPE"
    case aoaCat1A = "AOA Category 1A"
    case aoaCat1B = "AOA Category 1B"
    case aoaCat2A = "AOA Category 2A"
    case aoaCat2B = "AOA Category 2B"
    case stateSpecific = "State-Specific"
    case other = "Other"
}

@Model
class CMEActivity {
    var id: UUID
    var activityTitle: String
    var provider: String
    var creditType: String
    var hours: Double
    var dateCompleted: Date
    var notes: String?
    var createdAt: Date

    init(
        activityTitle: String = "",
        provider: String = "",
        creditType: String = CMECreditType.amaPRA1.rawValue,
        hours: Double = 0,
        dateCompleted: Date = Date(),
        notes: String? = nil
    ) {
        self.id = UUID()
        self.activityTitle = activityTitle
        self.provider = provider
        self.creditType = creditType
        self.hours = hours
        self.dateCompleted = dateCompleted
        self.notes = notes
        self.createdAt = Date()
    }

    var cmeType: CMECreditType {
        CMECreditType(rawValue: creditType) ?? .other
    }
}
