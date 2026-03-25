import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()
    @Binding var onboardingComplete: Bool

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            Group {
                switch viewModel.currentPage {
                case 0: OnboardingWelcomeView(viewModel: viewModel)
                case 1: OnboardingProfessionView(viewModel: viewModel)
                case 2: OnboardingStatesView(viewModel: viewModel)
                case 3: OnboardingCredentialTypesView(viewModel: viewModel)
                case 4: OnboardingNotificationsView(viewModel: viewModel)
                case 5:
                    if SubscriptionManager.subscriptionsOfferedInApp {
                        OnboardingTrialReminderView(viewModel: viewModel)
                    } else {
                        OnboardingFreeReleaseReminderView(viewModel: viewModel)
                    }
                case 6:
                    if SubscriptionManager.subscriptionsOfferedInApp {
                        PaywallView(
                            onDismiss: { completeOnboarding(isPro: false) },
                            onSubscribe: { completeOnboarding(isPro: true) }
                        )
                    } else {
                        OnboardingFreeReleaseFinishView {
                            completeOnboarding(isPro: true)
                        }
                    }
                default: OnboardingWelcomeView(viewModel: viewModel)
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentPage)
        }
    }

    private func completeOnboarding(isPro: Bool) {
        viewModel.saveProfile(modelContext: modelContext)
        withAnimation(.spring(duration: 0.5)) {
            onboardingComplete = true
        }
    }
}
