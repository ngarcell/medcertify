import SwiftUI

struct OnboardingWelcomeView: View {
    let viewModel: OnboardingViewModel
    @State private var animateIn: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Theme.medicalBlue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 52))
                        .foregroundStyle(Theme.medicalBlue)
                        .symbolEffect(.bounce, value: animateIn)
                }
                .scaleEffect(animateIn ? 1 : 0.5)
                .opacity(animateIn ? 1 : 0)

                VStack(spacing: 12) {
                    Text("Never risk a\nlicense lapse.")
                        .font(.system(.largeTitle, weight: .bold))
                        .multilineTextAlignment(.center)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)

                    Text("Track every credential, certificate,\nand CME hour — all in one place.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                }
            }

            Spacer()

            VStack(spacing: 20) {
                ValueBullet(icon: "checklist", text: "Track licenses, certifications, and DEA in one place")
                ValueBullet(icon: "bell.badge.fill", text: "Get renewal reminders months in advance")
                ValueBullet(icon: "doc.text.fill", text: "Log CME credits with certificate storage")
            }
            .padding(.horizontal, 24)
            .opacity(animateIn ? 1 : 0)

            Spacer()

            VStack(spacing: 8) {
                Button {
                    viewModel.nextPage()
                } label: {
                    Text("Get Started — Free")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.medicalBlue)

                Text("Set up in 2 minutes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
                animateIn = true
            }
        }
    }
}

struct ValueBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Theme.medicalBlue)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
    }
}
