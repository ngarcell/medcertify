import SwiftUI

/// Shown in place of the trial-reminder step when the app ships without in-app subscriptions.
struct OnboardingFreeReleaseReminderView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            onboardingHeader(
                step: 6,
                title: "You’re almost ready.",
                subtitle: "The free release keeps the same professional structure: deadlines, proof, and reminders in one desk."
            )

            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "Renewal reminders on your schedule")
                BulletPoint(text: "Education and vault tools included")
                BulletPoint(text: "Your data stays on this device")
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)

            Spacer()

            onboardingFooterButton(title: "Continue", action: viewModel.nextPage)
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
                VStack(spacing: 8) {
                    Text("Your desk is ready.")
                        .font(Theme.display(32, relativeTo: .title, prominent: true))
                        .multilineTextAlignment(.center)

                    Text("Start tracking credentials, continuing education, and proof with a cleaner system than the one you started with.")
                        .font(Theme.ui(16))
                        .foregroundStyle(Theme.mutedLabel)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, Theme.screenPadding)

            Spacer()

            Button {
                onFinish()
            } label: {
                Text("Open MedCertify")
                    .font(Theme.ui(17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Theme.primaryGradient, in: RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.screenPadding)
            .padding(.bottom, 18)
        }
    }
}
