import SwiftUI

struct OnboardingWelcomeView: View {
    let viewModel: OnboardingViewModel
    @State private var animateIn: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 28)

            VStack(alignment: .leading, spacing: 22) {
                Text("MedCertify")
                    .font(Theme.ui(13, weight: .semibold))
                    .tracking(2.6)
                    .foregroundStyle(Theme.copper)
                    .opacity(animateIn ? 1 : 0)

                Text("A credential desk built for real clinical work.")
                    .font(Theme.display(40, relativeTo: .largeTitle, prominent: true))
                    .foregroundStyle(Theme.headerText)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 18)

                Text("Keep licenses, board renewals, education credits, and proof in one calm system you can trust when a deadline gets close.")
                    .font(Theme.ui(17))
                    .foregroundStyle(Theme.mutedLabel)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 18)
            }
            .padding(.horizontal, Theme.screenPadding)

            VStack(spacing: 14) {
                welcomeFeature(title: "Renewal-ready at a glance", subtitle: "See what needs action before a board or employer asks.")
                welcomeFeature(title: "Proof where you need it", subtitle: "Store certificates and confirmations with the right credential.")
                welcomeFeature(title: "Built around your role", subtitle: "Physicians, APPs, nurses, pharmacists, and dental teams can all make it their own.")
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 30)
            .opacity(animateIn ? 1 : 0)

            Spacer()

            VStack(spacing: 10) {
                Button {
                    viewModel.nextPage()
                } label: {
                    Text("Set up my credential desk")
                        .font(Theme.ui(17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Theme.primaryGradient, in: RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)

                Text("Local-first. No patient data. Setup takes a minute or two.")
                    .font(Theme.ui(13))
                    .foregroundStyle(Theme.mutedLabel)
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.bottom, 20)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
                animateIn = true
            }
        }
    }

    private func welcomeFeature(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.ui(17, weight: .semibold))
                .foregroundStyle(Theme.bodyText)
            Text(subtitle)
                .font(Theme.ui(14))
                .foregroundStyle(Theme.mutedLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.cardPadding)
        .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .stroke(Theme.subtleBorder, lineWidth: 1)
        }
    }
}
