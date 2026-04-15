import SwiftUI

struct OnboardingTrialReminderView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            onboardingHeader(
                step: 6,
                title: "Trial reminders stay transparent.",
                subtitle: "If you start a trial, MedCertify will warn you before it ends. No surprise billing copy, no pressure."
            )

            VStack(spacing: 16) {
                TrialTimelineItem(day: "Today", description: "Full access starts", icon: "play.circle.fill", color: Theme.statusGreen)
                TrialTimelineItem(day: "Day 6", description: "MedCertify sends a heads-up reminder", icon: "bell.fill", color: Theme.copper)
                TrialTimelineItem(day: "Day 7", description: "Trial ends — manage anytime in Settings", icon: "clock.fill", color: Theme.statusBlue)
            }
            .padding(20)
            .background(Theme.surfaceCard)
            .clipShape(.rect(cornerRadius: Theme.radiusLarge))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.radiusLarge)
                    .stroke(Theme.subtleBorder, lineWidth: 1)
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 28)

            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "7 days of full access to the premium workflow")
                BulletPoint(text: "Cancel anytime in system Settings")
                BulletPoint(text: "Reminder scheduled before the billing date")
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)

            Spacer()

            onboardingFooterButton(title: "Continue", action: viewModel.nextPage)
        }
    }
}

struct TrialTimelineItem: View {
    let day: String
    let description: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(day)
                    .font(Theme.ui(15, weight: .semibold))
                Text(description)
                    .font(Theme.ui(13))
                    .foregroundStyle(Theme.mutedLabel)
            }
            Spacer()
        }
    }
}

struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.statusGreen)
                .padding(.top, 2)
            Text(text)
                .font(Theme.ui(14))
                .foregroundStyle(Theme.mutedLabel)
        }
    }
}
