import SwiftUI
import UserNotifications

struct OnboardingNotificationsView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            onboardingHeader(
                step: 5,
                title: "Keep the calm even when a deadline is coming.",
                subtitle: "Turn on reminders so MedCertify can surface renewals early enough to act."
            )

            VStack(spacing: 12) {
                NotificationPreview(
                    icon: "cross.case",
                    title: "License Renewal",
                    message: "Texas license renews in 90 days. Proof and checklist are ready to review.",
                    time: "9:00 AM"
                )
                NotificationPreview(
                    icon: "calendar.badge.clock",
                    title: "Credential Desk",
                    message: "Two items need attention this month. Open MedCertify to review the next deadline.",
                    time: "Mon"
                )
                NotificationPreview(
                    icon: "doc.richtext",
                    title: "Proof Stored",
                    message: "Renewal confirmation scanned and ready in your vault.",
                    time: "Yesterday"
                )
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 28)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    requestNotifications()
                } label: {
                    Text("Enable Reminders")
                        .font(Theme.ui(17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Theme.primaryGradient, in: RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.nextPage()
                } label: {
                    Text("Not now")
                        .font(Theme.ui(15, weight: .medium))
                        .foregroundStyle(Theme.mutedLabel)
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.bottom, 18)
        }
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                viewModel.notificationsEnabled = granted
                viewModel.nextPage()
            }
        }
    }
}

struct NotificationPreview: View {
    let icon: String
    let title: String
    let message: String
    let time: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.inkAccent)
                .frame(width: 36, height: 36)
                .background(Theme.inkAccent.opacity(0.1))
                .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(Theme.ui(13, weight: .semibold))
                    Spacer()
                    Text(time)
                        .font(Theme.ui(11))
                        .foregroundStyle(Theme.mutedLabel)
                }
                Text(message)
                    .font(Theme.ui(13))
                    .foregroundStyle(Theme.mutedLabel)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Theme.surfaceCard)
        .clipShape(.rect(cornerRadius: Theme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .stroke(Theme.subtleBorder, lineWidth: 1)
        }
    }
}
