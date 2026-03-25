import SwiftUI

struct OnboardingStatesView: View {
    let viewModel: OnboardingViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 56), spacing: 8)
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Where are you licensed?")
                    .font(.title.bold())
                Text("Select all states where you hold a license.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            .padding(.horizontal, 24)

            if !viewModel.selectedStates.isEmpty {
                Text("\(viewModel.selectedStates.count) state\(viewModel.selectedStates.count == 1 ? "" : "s") selected")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Theme.medicalBlue)
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
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }

            VStack {
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
                .disabled(viewModel.selectedStates.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .background(.bar)
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
                .font(.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(width: 52, height: 40)
                .background(isSelected ? Theme.medicalBlue : Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 10))
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
