import SwiftUI

enum Theme {
    static let medicalBlue = Color(red: 0.07, green: 0.27, blue: 0.71)
    static let medicalBlueSecondary = Color(red: 0.19, green: 0.41, blue: 0.74)
    static let credentialGold = Color(red: 0.98, green: 0.70, blue: 0.12)
    static let warningGold = Color(red: 0.99, green: 0.72, blue: 0.19)
    static let statusGreen = Color(red: 0.08, green: 0.50, blue: 0.24)
    static let statusAmber = Color(red: 0.91, green: 0.60, blue: 0.09)
    static let statusRed = Color(red: 0.78, green: 0.16, blue: 0.14)
    static let statusBlue = Color(red: 0.15, green: 0.39, blue: 0.88)
    static let darkNavy = Color(red: 0.06, green: 0.10, blue: 0.19)
    static let headerText = Color(red: 0.06, green: 0.10, blue: 0.19)
    static let mutedLabel = Color(red: 0.44, green: 0.47, blue: 0.56)
    static let surfaceBase = Color(.systemGroupedBackground)
    static let surfaceRaised = Color(.secondarySystemBackground)
    static let surfaceCard = Color(.systemBackground)
    static let subtleBorder = Color.black.opacity(0.05)

    static let primaryGradient = LinearGradient(
        colors: [medicalBlue, medicalBlueSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func statusColor(for status: CredentialStatus) -> Color {
        switch status {
        case .current: return statusGreen
        case .expiringSoon: return statusAmber
        case .expired: return statusRed
        case .pending: return statusBlue
        }
    }
}
