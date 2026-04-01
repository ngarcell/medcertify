import SwiftUI

struct OnboardingTrialReminderView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Theme.medicalBlue.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.medicalBlue)
                }

                VStack(spacing: 8) {
                    Text("We'll remind you before\nyour free trial ends")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text("No surprises. Full transparency.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 16) {
                TrialTimelineItem(day: "Today", description: "Full access starts", icon: "play.circle.fill", color: Theme.statusGreen)
                TrialTimelineItem(day: "Day 6", description: "We'll send you a reminder", icon: "bell.fill", color: Theme.credentialGold)
                TrialTimelineItem(day: "Day 7", description: "Trial ends — cancel anytime", icon: "clock.fill", color: Theme.statusBlue)
            }
            .padding(20)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 16))
            .padding(.horizontal, 24)
            .padding(.top, 32)

            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "Full access for 7 days — unlimited credentials")
                BulletPoint(text: "Cancel anytime with one tap")
                BulletPoint(text: "We'll notify you 24 hours before trial ends")
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)

            Spacer()

            Button {
                viewModel.nextPage()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.medicalBlue)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
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
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
