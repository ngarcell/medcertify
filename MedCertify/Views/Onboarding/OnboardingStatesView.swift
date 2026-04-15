import SwiftUI

struct OnboardingStatesView: View {
    let viewModel: OnboardingViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 56), spacing: 8)
    ]

    var body: some View {
        VStack(spacing: 0) {
            onboardingHeader(
                step: 2,
                title: "Where are you licensed?",
                subtitle: "We’ll use this to keep the app grounded in your real working footprint."
            )

            if !viewModel.selectedStates.isEmpty {
                Text("\(viewModel.selectedStates.count) state\(viewModel.selectedStates.count == 1 ? "" : "s") selected")
                    .font(Theme.ui(13, weight: .semibold))
                    .foregroundStyle(Theme.copper)
                    .padding(.top, 12)
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Constants.usStates, id: \.self) { state in
                        StateChip(
                            state: state,
                            isSelected: viewModel.selectedStates.contains(state)
                        ) {
                            withAnimation(.spring(duration: 0.2)) {
                                if viewModel.selectedStates.contains(state) {
                                    viewModel.selectedStates.remove(state)
                                } else {
                                    viewModel.selectedStates.insert(state)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }

            onboardingFooterButton(title: "Continue", isDisabled: viewModel.selectedStates.isEmpty, action: viewModel.nextPage)
        }
    }
}

struct StateChip: View {
    let state: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(state)
                .font(Theme.ui(13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Theme.bodyText)
                .frame(width: 52, height: 40)
                .background(isSelected ? Theme.primaryGradient : LinearGradient(colors: [Theme.surfaceCard], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(.rect(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.clear : Theme.subtleBorder, lineWidth: 1)
                }
        }
        .sensoryFeedback(.selection, trigger: isSelected)
        .buttonStyle(.plain)
    }
}
