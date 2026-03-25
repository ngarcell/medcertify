import Foundation

enum Constants {
    static let maxFreeCredentials = 3
    static let appName = "MedCertify"
    static let monthlyPrice = "$9.99"
    static let annualPrice = "$49.99"
    static let annualMonthlyEquivalent = "$4.17"

    // MARK: - Support & Legal
    static let supportEmail = "support@socialreporthq.com"
    static let privacyURL = "https://socialreporthq.com/medcertify/privacy"
    static let termsURL = "https://socialreporthq.com/medcertify/terms"
    static let supportURL = "https://socialreporthq.com/medcertify/support"

    static let professions: [(name: String, icon: String)] = [
        ("Physician (MD/DO)", "stethoscope"),
        ("Nurse (RN/NP/APRN)", "cross.circle.fill"),
        ("Physician Assistant", "person.badge.plus"),
        ("Pharmacist", "pills.circle.fill"),
        ("Dentist / Dental Hygienist", "mouth.fill"),
        ("Other Healthcare Professional", "heart.text.clipboard")
    ]

    static let usStates: [String] = [
        "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL",
        "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME",
        "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH",
        "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "PR",
        "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "VI", "WA",
        "WV", "WI", "WY"
    ]

    static let stateNames: [String: String] = [
        "AL": "Alabama", "AK": "Alaska", "AZ": "Arizona", "AR": "Arkansas",
        "CA": "California", "CO": "Colorado", "CT": "Connecticut", "DE": "Delaware",
        "DC": "District of Columbia", "FL": "Florida", "GA": "Georgia", "HI": "Hawaii",
        "ID": "Idaho", "IL": "Illinois", "IN": "Indiana", "IA": "Iowa",
        "KS": "Kansas", "KY": "Kentucky", "LA": "Louisiana", "ME": "Maine",
        "MD": "Maryland", "MA": "Massachusetts", "MI": "Michigan", "MN": "Minnesota",
        "MS": "Mississippi", "MO": "Missouri", "MT": "Montana", "NE": "Nebraska",
        "NV": "Nevada", "NH": "New Hampshire", "NJ": "New Jersey", "NM": "New Mexico",
        "NY": "New York", "NC": "North Carolina", "ND": "North Dakota", "OH": "Ohio",
        "OK": "Oklahoma", "OR": "Oregon", "PA": "Pennsylvania", "PR": "Puerto Rico",
        "RI": "Rhode Island", "SC": "South Carolina", "SD": "South Dakota",
        "TN": "Tennessee", "TX": "Texas", "UT": "Utah", "VT": "Vermont",
        "VA": "Virginia", "VI": "Virgin Islands", "WA": "Washington",
        "WV": "West Virginia", "WI": "Wisconsin", "WY": "Wyoming"
    ]

    static let credentialTypes: [(name: String, icon: String)] = [
        ("State License", "building.columns.fill"),
        ("Board Certification", "medal.fill"),
        ("DEA Registration", "pills.fill"),
        ("Controlled Substance License", "cross.vial.fill"),
        ("Hospital Privileges", "cross.case.fill"),
        ("Malpractice Insurance", "shield.checkered"),
        ("CME/CE Credits", "book.fill"),
        ("BLS/ACLS/PALS", "heart.circle.fill"),
        ("NPI Registration", "number.circle.fill"),
        ("Specialty Certification", "star.circle.fill")
    ]

    static func defaultCredentialTypes(for profession: String) -> [String] {
        switch profession {
        case "Physician (MD/DO)":
            return ["State License", "Board Certification", "DEA Registration", "Hospital Privileges", "Malpractice Insurance", "CME/CE Credits", "BLS/ACLS/PALS", "NPI Registration"]
        case "Nurse (RN/NP/APRN)":
            return ["State License", "Board Certification", "Malpractice Insurance", "CME/CE Credits", "BLS/ACLS/PALS", "NPI Registration"]
        case "Physician Assistant":
            return ["State License", "Board Certification", "DEA Registration", "CME/CE Credits", "BLS/ACLS/PALS", "NPI Registration"]
        case "Pharmacist":
            return ["State License", "Controlled Substance License", "CME/CE Credits", "NPI Registration"]
        default:
            return ["State License", "CME/CE Credits", "BLS/ACLS/PALS"]
        }
    }
}
