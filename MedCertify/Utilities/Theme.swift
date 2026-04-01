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
    static let surfaceMuted = Color(.secondarySystemGroupedBackground)
    static let subtleBorder = Color.black.opacity(0.05)
    static let cardShadow = Color.black.opacity(0.05)

    static let screenPadding: CGFloat = 24
    static let sectionSpacing: CGFloat = 28
    static let cardSpacing: CGFloat = 16
    static let largeCornerRadius: CGFloat = 24
    static let mediumCornerRadius: CGFloat = 18
    static let smallCornerRadius: CGFloat = 12

    static let primaryGradient = LinearGradient(
        colors: [medicalBlue, medicalBlueSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [Color.white.opacity(0.96), Color.white.opacity(0.72)],
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

struct MedCertifyCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.surfaceCard)
            .clipShape(.rect(cornerRadius: Theme.largeCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.largeCornerRadius)
                    .stroke(Theme.subtleBorder, lineWidth: 1)
            }
            .shadow(color: Theme.cardShadow, radius: 16, y: 8)
    }
}

struct MedCertifySecondaryCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.surfaceRaised)
            .clipShape(.rect(cornerRadius: Theme.largeCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.largeCornerRadius)
                    .stroke(Theme.subtleBorder, lineWidth: 1)
            }
    }
}

extension View {
    func medCertifyCard() -> some View {
        modifier(MedCertifyCardModifier())
    }

    func medCertifySecondaryCard() -> some View {
        modifier(MedCertifySecondaryCardModifier())
    }
}

struct MedCertifyHeroBackground: View {
    var body: some View {
        ZStack {
            Theme.surfaceBase.ignoresSafeArea()

            LinearGradient(
                colors: [
                    Theme.medicalBlue.opacity(0.18),
                    Theme.surfaceBase,
                    Theme.surfaceBase
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}

struct MedCertifySectionEyebrow: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.medium))
            .tracking(3.2)
            .foregroundStyle(Theme.mutedLabel)
    }
}

struct MedCertifyFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.medicalBlue)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
    }
}

struct MedCertifyLockedFeatureView: View {
    let title: String
    let message: String
    let actionTitle: String
    let features: [(icon: String, text: String)]
    let action: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Theme.medicalBlue.opacity(0.08))
                        .frame(width: 96, height: 96)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Theme.credentialGold)
                }

                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(Theme.headerText)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: 12) {
                ForEach(features, id: \.text) { feature in
                    MedCertifyFeatureRow(icon: feature.icon, text: feature.text)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: action) {
                Label(actionTitle, systemImage: "crown.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.medicalBlue)
            .padding(.horizontal, Theme.screenPadding)
            .padding(.bottom, 16)
        }
        .background(MedCertifyHeroBackground())
    }
}
