import SwiftUI
import UserNotifications

struct OnboardingNotificationsView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.credentialGold)

                VStack(spacing: 8) {
                    Text("Never miss a\nrenewal deadline")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text("We'll remind you months in advance — not days.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 12) {
                NotificationPreview(
                    icon: "doc.text.fill",
                    title: "License Renewal",
                    message: "Texas medical license renews in 90 days — start your CME review",
                    time: "9:00 AM"
                )
                NotificationPreview(
                    icon: "book.fill",
                    title: "CME Progress",
                    message: "You need 12 more CME hours before Dec 31",
                    time: "Mon"
                )
                NotificationPreview(
                    icon: "checkmark.circle.fill",
                    title: "Renewed",
                    message: "DEA registration renewed — logged to your vault",
                    time: "Yesterday"
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    requestNotifications()
                } label: {
                    Text("Enable Reminders")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.medicalBlue)

                Button {
                    viewModel.nextPage()
                } label: {
                    Text("Not now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
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
                .foregroundStyle(Theme.medicalBlue)
                .frame(width: 36, height: 36)
                .background(Theme.medicalBlue.opacity(0.1))
                .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.footnote.weight(.semibold))
                    Spacer()
                    Text(time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
    }
}
