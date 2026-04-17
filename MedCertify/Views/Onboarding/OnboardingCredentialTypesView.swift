import SwiftUI

struct OnboardingCredentialTypesView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("What do you need to track?")
                    .font(.title.bold())
                Text("We've pre-selected the most common for your profession.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.horizontal, 24)

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
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 100)
            }

            VStack(spacing: 8) {
                if !viewModel.selectedCredentialTypes.isEmpty {
                    Text("\(viewModel.selectedCredentialTypes.count) credentials — MedCertify will track all of these")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Theme.medicalBlue)
                }

                Button {
                    viewModel.nextPage()
                } label: {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.medicalBlue)
                .disabled(viewModel.selectedCredentialTypes.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .background(.bar)
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
                    .foregroundStyle(isSelected ? Theme.medicalBlue : .secondary)
                    .frame(width: 32)

                Text(name)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.medicalBlue : Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
