import SwiftUI

struct OnboardingProfessionView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("What's your profession?")
                    .font(.title.bold())
                Text("This helps us customize your credential tracker.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            .padding(.horizontal, 24)

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
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                viewModel.selectedCredentialTypes = Set(Constants.defaultCredentialTypes(for: profession.name))
                                viewModel.nextPage()
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }
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
                    .foregroundStyle(isSelected ? .white : Theme.medicalBlue)
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .background(isSelected ? Theme.medicalBlue : Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Theme.medicalBlue : Color.clear, lineWidth: 2)
            )
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
