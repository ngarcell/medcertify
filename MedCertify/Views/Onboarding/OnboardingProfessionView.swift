import SwiftUI

struct OnboardingProfessionView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            onboardingHeader(
                step: 1,
                title: "Who is this desk for?",
                subtitle: "We’ll use your name and role to personalize the experience without changing the underlying data model."
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("First name")
                    .font(Theme.ui(13, weight: .semibold))
                    .foregroundStyle(Theme.mutedLabel)

                TextField("Jordan", text: Binding(
                    get: { viewModel.name },
                    set: { viewModel.name = $0 }
                ))
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusMedium))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.radiusMedium)
                        .stroke(Theme.subtleBorder, lineWidth: 1)
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 20)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(Constants.professions, id: \.name) { profession in
                        ProfessionCard(
                            name: profession.name,
                            icon: profession.icon,
                            isSelected: viewModel.profession == profession.name
                        ) {
                            withAnimation(.spring(duration: 0.3)) {
                                viewModel.profession = profession.name
                            }
                            viewModel.selectedCredentialTypes = Set(Constants.defaultCredentialTypes(for: profession.name))
                        }
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }

            onboardingFooterButton(
                title: "Continue",
                isDisabled: viewModel.profession.isEmpty || viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                action: viewModel.nextPage
            )
        }
    }
}

struct ProfessionCard: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(isSelected ? .white : Theme.inkAccent)
                Text(name)
                    .font(Theme.ui(14, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : Theme.bodyText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .background(isSelected ? Theme.primaryGradient : LinearGradient(colors: [Theme.surfaceCard], startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(.rect(cornerRadius: Theme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                    .strokeBorder(isSelected ? Theme.inkAccent.opacity(0.2) : Theme.subtleBorder, lineWidth: 1)
            }
        }
        .sensoryFeedback(.selection, trigger: isSelected)
        .buttonStyle(.plain)
    }
}
