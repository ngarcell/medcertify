import SwiftUI

struct OnboardingCredentialTypesView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            onboardingHeader(
                step: 3,
                title: "What needs to stay renewal-ready?",
                subtitle: "We preselected the usual set for \(viewModel.profession.isEmpty ? "your role" : viewModel.profession). Adjust anything you want."
            )

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Constants.credentialTypes, id: \.name) { credType in
                        CredentialTypeRow(
                            name: credType.name,
                            icon: credType.icon,
                            isSelected: viewModel.selectedCredentialTypes.contains(credType.name)
                        ) {
                            withAnimation(.spring(duration: 0.2)) {
                                if viewModel.selectedCredentialTypes.contains(credType.name) {
                                    viewModel.selectedCredentialTypes.remove(credType.name)
                                } else {
                                    viewModel.selectedCredentialTypes.insert(credType.name)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 24)
                .padding(.bottom, 100)
            }

            VStack(spacing: 8) {
                if !viewModel.selectedCredentialTypes.isEmpty {
                    Text("\(viewModel.selectedCredentialTypes.count) credentials — MedCertify will track all of these")
                        .font(Theme.ui(13, weight: .semibold))
                        .foregroundStyle(Theme.copper)
                }

                onboardingFooterButton(title: "Continue", isDisabled: viewModel.selectedCredentialTypes.isEmpty, action: viewModel.nextPage)
            }
        }
    }
}

struct CredentialTypeRow: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.inkAccent : Theme.mutedLabel)
                    .frame(width: 32)

                Text(name)
                    .font(Theme.ui(16, weight: .medium))
                    .foregroundStyle(Theme.bodyText)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.inkAccent : Theme.mutedLabel.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.surfaceCard)
            .clipShape(.rect(cornerRadius: Theme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                    .stroke(isSelected ? Theme.inkAccent.opacity(0.25) : Theme.subtleBorder, lineWidth: 1)
            }
        }
        .sensoryFeedback(.selection, trigger: isSelected)
        .buttonStyle(.plain)
    }
}
