import SwiftUI

/// Shown in place of the trial-reminder step when the app ships without in-app subscriptions.
struct OnboardingFreeReleaseReminderView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Theme.medicalBlue.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.medicalBlue)
                }

                VStack(spacing: 8) {
                    Text("Stay ahead of renewals")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text("Turn on notifications so we can remind you before credentials expire.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "Renewal reminders on your schedule")
                BulletPoint(text: "CME and document tools included")
                BulletPoint(text: "Your data stays on this device")
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)

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

/// Final onboarding step when subscriptions are not offered (no paywall).
struct OnboardingFreeReleaseFinishView: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Theme.medicalBlue.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.medicalBlue)
                }

                VStack(spacing: 8) {
                    Text("You're all set")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text("Start tracking credentials, CME, and documents.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                onFinish()
            } label: {
                Text("Get started")
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
