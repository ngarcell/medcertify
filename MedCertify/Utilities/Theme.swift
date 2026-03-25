import SwiftUI

enum Theme {
    static let medicalBlue = Color(red: 0.118, green: 0.251, blue: 0.686)
    static let credentialGold = Color(red: 0.851, green: 0.467, blue: 0.024)
    static let statusGreen = Color(red: 0.082, green: 0.502, blue: 0.239)
    static let statusAmber = Color(red: 0.851, green: 0.467, blue: 0.024)
    static let statusRed = Color(red: 0.863, green: 0.149, blue: 0.149)
    static let statusBlue = Color(red: 0.149, green: 0.388, blue: 0.878)
    static let darkNavy = Color(red: 0.059, green: 0.090, blue: 0.165)

    static func statusColor(for status: CredentialStatus) -> Color {
        switch status {
        case .current: return statusGreen
        case .expiringSoon: return statusAmber
        case .expired: return statusRed
        case .pending: return statusBlue
        }
    }
}
