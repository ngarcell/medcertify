import SwiftData
import Foundation

nonisolated enum CredentialType: String, Codable, CaseIterable, Sendable {
    case stateLicense = "State License"
    case boardCertification = "Board Certification"
    case dea = "DEA Registration"
    case controlledSubstance = "Controlled Substance License"
    case hospitalPrivileges = "Hospital Privileges"
    case malpracticeInsurance = "Malpractice Insurance"
    case blsAclsPals = "BLS/ACLS/PALS"
    case npi = "NPI Registration"
    case specialtyCertification = "Specialty Certification"
    case other = "Other"

    var icon: String {
        switch self {
        case .stateLicense: return "building.columns.fill"
        case .boardCertification: return "medal.fill"
        case .dea: return "pills.fill"
        case .controlledSubstance: return "cross.vial.fill"
        case .hospitalPrivileges: return "cross.case.fill"
        case .malpracticeInsurance: return "shield.checkered"
        case .blsAclsPals: return "heart.circle.fill"
        case .npi: return "number.circle.fill"
        case .specialtyCertification: return "star.circle.fill"
        case .other: return "doc.circle.fill"
        }
    }

    var category: String {
        switch self {
        case .stateLicense: return "Licenses"
        case .boardCertification: return "Board Certifications"
        case .dea, .controlledSubstance: return "DEA & Controlled Substance"
        case .hospitalPrivileges: return "Hospital Privileges"
        case .malpracticeInsurance: return "Insurance & Liability"
        case .blsAclsPals: return "BLS/ACLS/PALS"
        case .npi: return "NPI"
        case .specialtyCertification: return "Specialty Certifications"
        case .other: return "Other"
        }
    }
}

nonisolated enum CredentialStatus: String, Codable, Sendable {
    case current = "Current"
    case expiringSoon = "Expiring Soon"
    case expired = "Expired"
    case pending = "Pending"

    var icon: String {
        switch self {
        case .current: return "checkmark.circle.fill"
        case .expiringSoon: return "exclamationmark.triangle.fill"
        case .expired: return "xmark.circle.fill"
        case .pending: return "clock.fill"
        }
    }
}

@Model
class Credential {
    var id: UUID
    var type: String
    var name: String
    var issuingBody: String
    var state: String?
    var credentialNumber: String?
    var issueDate: Date?
    var expirationDate: Date?
    var renewalCycleMonths: Int
    var notes: String?
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var checklistItems: [ChecklistItem]
    @Relationship(deleteRule: .cascade) var renewalHistories: [RenewalHistory]
    var reminderDays: [Int]

    init(
        type: String = CredentialType.stateLicense.rawValue,
        name: String = "",
        issuingBody: String = "",
        state: String? = nil,
        credentialNumber: String? = nil,
        issueDate: Date? = nil,
        expirationDate: Date? = nil,
        renewalCycleMonths: Int = 24,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.name = name
        self.issuingBody = issuingBody
        self.state = state
        self.credentialNumber = credentialNumber
        self.issueDate = issueDate
        self.expirationDate = expirationDate
        self.renewalCycleMonths = renewalCycleMonths
        self.notes = notes
        self.createdAt = Date()
        self.checklistItems = []
        self.renewalHistories = []
        self.reminderDays = [180, 90, 60, 30, 14, 7, 3, 1]
    }

    var credentialType: CredentialType {
        CredentialType(rawValue: type) ?? .other
    }

    var status: CredentialStatus {
        guard let expDate = expirationDate else { return .pending }
        let now = Date()
        if expDate < now { return .expired }
        let daysUntil = Calendar.current.dateComponents([.day], from: now, to: expDate).day ?? 0
        if daysUntil <= 90 { return .expiringSoon }
        return .current
    }

    var daysUntilExpiration: Int? {
        guard let expDate = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expDate).day
    }

    var statusColor: String {
        switch status {
        case .current: return "statusGreen"
        case .expiringSoon: return "statusAmber"
        case .expired: return "statusRed"
        case .pending: return "statusBlue"
        }
    }
}
