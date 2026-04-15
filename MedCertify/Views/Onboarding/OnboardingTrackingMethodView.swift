import SwiftUI

struct OnboardingTrackingMethodView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            onboardingHeader(
                step: 4,
                title: "How are you keeping up today?",
                subtitle: "We’ll tune MedCertify around the system you’re replacing."
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Constants.trackingMethods, id: \.self) { method in
                        Button {
                            withAnimation(.spring(duration: 0.25)) {
                                viewModel.currentTrackingMethod = method
                            }
                        } label: {
                            HStack(spacing: 14) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.currentTrackingMethod == method ? Theme.primaryGradient : LinearGradient(colors: [Theme.surfaceMuted], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        Image(systemName: workflowIcon(for: method))
                                            .font(.headline)
                                            .foregroundStyle(viewModel.currentTrackingMethod == method ? .white : Theme.inkAccent)
                                    }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(method.capitalized)
                                        .font(Theme.ui(17, weight: .semibold))
                                        .foregroundStyle(Theme.bodyText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(workflowDescription(for: method))
                                        .font(Theme.ui(13))
                                        .foregroundStyle(Theme.mutedLabel)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                Image(systemName: viewModel.currentTrackingMethod == method ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(viewModel.currentTrackingMethod == method ? Theme.inkAccent : Theme.mutedLabel.opacity(0.6))
                            }
                            .padding(18)
                            .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusMedium))
                            .overlay {
                                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                    .stroke(viewModel.currentTrackingMethod == method ? Theme.inkAccent.opacity(0.35) : Theme.subtleBorder, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 20)
                .padding(.bottom, 120)
            }

            onboardingFooterButton(
                title: "Continue",
                isDisabled: viewModel.currentTrackingMethod.isEmpty,
                action: viewModel.nextPage
            )
        }
    }

    private func workflowIcon(for method: String) -> String {
        switch method {
        case "a spreadsheet":
            return "tablecells"
        case "calendar reminders":
            return "calendar"
        case "email folders":
            return "tray.full"
        case "a hospital or board portal":
            return "building.2"
        case "paper notes or a binder":
            return "note.text"
        default:
            return "brain.head.profile"
        }
    }

    private func workflowDescription(for method: String) -> String {
        switch method {
        case "a spreadsheet":
            return "Bring dates, proof, and renewal notes into one place."
        case "calendar reminders":
            return "Pair alerts with credential records and supporting proof."
        case "email folders":
            return "Stop hunting through inboxes when a board asks for proof."
        case "a hospital or board portal":
            return "Keep a personal readiness layer outside each portal."
        case "paper notes or a binder":
            return "Replace manual tracking with a portable credential desk."
        default:
            return "Build a system before the next renewal gets close."
        }
    }
}

@ViewBuilder
func onboardingHeader(step: Int, title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 14) {
        HStack(spacing: 10) {
            Text("STEP \(step)")
                .font(Theme.ui(12, weight: .semibold))
                .tracking(1.6)
                .foregroundStyle(Theme.copper)

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 99)
                    .fill(Theme.subtleBorder)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 99)
                            .fill(Theme.primaryGradient)
                            .frame(width: geo.size.width * (CGFloat(step) / 6), height: 6)
                    }
            }
                .frame(height: 6)
        }

        Text(title)
            .font(Theme.display(31, relativeTo: .largeTitle, prominent: true))
            .foregroundStyle(Theme.headerText)

        Text(subtitle)
            .font(Theme.ui(16))
            .foregroundStyle(Theme.mutedLabel)
    }
    .padding(.horizontal, Theme.screenPadding)
    .padding(.top, 20)
}

@ViewBuilder
func onboardingFooterButton(title: String, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
    VStack(spacing: 0) {
        Divider()
            .background(Theme.subtleBorder)

        Button(action: action) {
            Text(title)
                .font(Theme.ui(17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(in: RoundedRectangle(cornerRadius: 18)) {
                    if isDisabled {
                        Theme.inkSoft.opacity(0.35)
                    } else {
                        Theme.primaryGradient
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
    .background(Theme.surfaceBase.opacity(0.96))
}
