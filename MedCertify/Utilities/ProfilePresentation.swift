import Foundation

extension UserProfile {
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var firstNameOrFallback: String {
        if let first = trimmedName.split(separator: " ").first, !first.isEmpty {
            return String(first)
        }
        return professionFriendlyName
    }

    var professionFriendlyName: String {
        profession.isEmpty ? "Clinician" : profession
    }

    var shortProfession: String {
        switch profession {
        case "Physician (MD/DO)":
            return "Physician"
        case "Nurse (RN/NP/APRN)":
            return "Nurse"
        case "Physician Assistant":
            return "Physician Assistant"
        case "Dentist / Dental Hygienist":
            return "Dental"
        case "Other Healthcare Professional":
            return "Healthcare Professional"
        default:
            return professionFriendlyName
        }
    }

    var initials: String {
        let source = trimmedName.isEmpty ? shortProfession : trimmedName
        let letters = source
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
        let value = String(letters)
        return value.isEmpty ? "MC" : value.uppercased()
    }

    var isPhysicianOrPA: Bool {
        profession == "Physician (MD/DO)" || profession == "Physician Assistant"
    }

    var educationTabTitle: String {
        isPhysicianOrPA ? "CME" : "CE"
    }

    var educationLongTitle: String {
        isPhysicianOrPA ? "Continuing Medical Education" : "Continuing Education"
    }

    var educationProgressTitle: String {
        isPhysicianOrPA ? "CME Progress" : "CE Progress"
    }

    var educationActivityTitle: String {
        isPhysicianOrPA ? "Log CME Activity" : "Log CE Activity"
    }

    var workflowSourceLabel: String {
        let workflow = currentTrackingMethod?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return workflow.isEmpty ? "You are building a cleaner system from scratch." : "You’re moving off \(workflow.lowercased())."
    }

    var licensedStateSummary: String {
        let count = selectedStates.count
        return count == 1 ? "1 licensed state" : "\(count) licensed states"
    }
}

extension Credential {
    var displayName: String {
        name.isEmpty ? credentialType.rawValue : name
    }

    var urgencyRank: Int {
        switch status {
        case .expired: return 0
        case .expiringSoon: return 1
        case .pending: return 2
        case .current: return expirationDate == nil ? 4 : 3
        }
    }

    var expirationDisplay: String {
        guard let expirationDate else { return "No expiration date" }
        return expirationDate.formatted(.dateTime.month(.abbreviated).day().year())
    }

    var dueStatusText: String {
        guard let daysUntilExpiration else { return "Expiration date needed" }
        if daysUntilExpiration < 0 {
            return "Expired \(abs(daysUntilExpiration))d ago"
        }
        if daysUntilExpiration == 0 {
            return "Expires today"
        }
        return "\(daysUntilExpiration)d remaining"
    }

    var metaLine: String {
        let issuer = issuingBody.isEmpty ? "Issuer not added" : issuingBody
        if let state, !state.isEmpty {
            return "\(state) • \(issuer)"
        }
        return issuer
    }

    var secondaryMetaLine: String {
        if let credentialNumber, !credentialNumber.isEmpty {
            return "#\(credentialNumber)"
        }
        return credentialType.rawValue
    }
}

extension CredentialDocument {
    var iconName: String {
        switch fileType.lowercased() {
        case "pdf":
            return "doc.richtext"
        case "image", "jpg", "jpeg", "png", "heic":
            return "photo.on.rectangle"
        default:
            return "doc.text"
        }
    }

    var fileBadgeText: String {
        fileType.uppercased()
    }
}
