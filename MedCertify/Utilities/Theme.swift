import SwiftUI
import UIKit

enum Theme {
    // MARK: - Palette

    static let ink = dynamicColor(light: UIColor(red: 0.09, green: 0.13, blue: 0.20, alpha: 1),
                                  dark: UIColor(red: 0.93, green: 0.94, blue: 0.96, alpha: 1))
    static let inkSoft = dynamicColor(light: UIColor(red: 0.30, green: 0.35, blue: 0.44, alpha: 1),
                                      dark: UIColor(red: 0.64, green: 0.68, blue: 0.75, alpha: 1))
    static let bone = dynamicColor(light: UIColor(red: 0.97, green: 0.95, blue: 0.92, alpha: 1),
                                   dark: UIColor(red: 0.10, green: 0.11, blue: 0.14, alpha: 1))
    static let boneElevated = dynamicColor(light: UIColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 1),
                                           dark: UIColor(red: 0.13, green: 0.14, blue: 0.18, alpha: 1))
    static let mist = dynamicColor(light: UIColor(red: 0.93, green: 0.92, blue: 0.89, alpha: 1),
                                   dark: UIColor(red: 0.17, green: 0.18, blue: 0.22, alpha: 1))
    static let inkAccent = dynamicColor(light: UIColor(red: 0.12, green: 0.24, blue: 0.42, alpha: 1),
                                        dark: UIColor(red: 0.41, green: 0.59, blue: 0.82, alpha: 1))
    static let copper = dynamicColor(light: UIColor(red: 0.68, green: 0.44, blue: 0.27, alpha: 1),
                                     dark: UIColor(red: 0.83, green: 0.62, blue: 0.42, alpha: 1))
    static let coolAccent = dynamicColor(light: UIColor(red: 0.27, green: 0.52, blue: 0.64, alpha: 1),
                                         dark: UIColor(red: 0.45, green: 0.68, blue: 0.79, alpha: 1))

    static let statusGreen = dynamicColor(light: UIColor(red: 0.19, green: 0.47, blue: 0.31, alpha: 1),
                                          dark: UIColor(red: 0.41, green: 0.74, blue: 0.55, alpha: 1))
    static let statusAmber = dynamicColor(light: UIColor(red: 0.67, green: 0.44, blue: 0.14, alpha: 1),
                                          dark: UIColor(red: 0.86, green: 0.66, blue: 0.30, alpha: 1))
    static let statusRed = dynamicColor(light: UIColor(red: 0.66, green: 0.21, blue: 0.18, alpha: 1),
                                        dark: UIColor(red: 0.88, green: 0.50, blue: 0.45, alpha: 1))
    static let statusBlue = dynamicColor(light: UIColor(red: 0.20, green: 0.39, blue: 0.67, alpha: 1),
                                         dark: UIColor(red: 0.43, green: 0.62, blue: 0.88, alpha: 1))

    // MARK: - Surfaces

    static let surfaceBase = bone
    static let surfaceRaised = boneElevated
    static let surfaceCard = boneElevated
    static let surfaceMuted = mist
    static let surfaceEmphasis = inkAccent
    static let headerText = ink
    static let bodyText = ink
    static let mutedLabel = inkSoft
    static let subtleBorder = dynamicColor(light: UIColor.black.withAlphaComponent(0.06),
                                           dark: UIColor.white.withAlphaComponent(0.08))

    static let primaryGradient = LinearGradient(
        colors: [inkAccent, coolAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let canvasGradient = LinearGradient(
        colors: [surfaceBase, surfaceRaised],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Typography

    static func display(_ size: CGFloat, relativeTo textStyle: Font.TextStyle, prominent: Bool = false) -> Font {
        Font.custom(prominent ? "NewYork-Medium" : "NewYork-Regular", size: size, relativeTo: textStyle)
    }

    static func ui(_ size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        .system(size: size, weight: weight, design: design)
    }

    // MARK: - Layout

    static let radiusSmall: CGFloat = 12
    static let radiusMedium: CGFloat = 18
    static let radiusLarge: CGFloat = 28
    static let screenPadding: CGFloat = 24
    static let cardPadding: CGFloat = 20

    // MARK: - Legacy aliases

    static let medicalBlue = inkAccent
    static let medicalBlueSecondary = coolAccent
    static let credentialGold = copper
    static let warningGold = copper
    static let darkNavy = ink

    static func statusColor(for status: CredentialStatus) -> Color {
        switch status {
        case .current: return statusGreen
        case .expiringSoon: return statusAmber
        case .expired: return statusRed
        case .pending: return statusBlue
        }
    }

    private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }
}
