import SwiftUI
import StoreKit

struct PaywallView: View {
    var onDismiss: () -> Void
    var onSubscribe: () -> Void
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var selectedPlan: Plan = .annual
    @State private var isLoading: Bool = false
    @State private var isLoadingProducts: Bool = true
    @State private var errorMessage: String?

    enum Plan { case annual, monthly }

    private var trialEndDate: String {
        let date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return date.formatted(.dateTime.month(.wide).day().year())
    }

    var body: some View {
        ZStack {
            MedCertifyHeroBackground()

            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    planSelector

                    if SubscriptionManager.subscriptionsOfferedInApp, !isLoadingProducts, !selectedProductReady {
                        Text("Couldn’t load subscription options. Pull down to try again.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 16)
                    }

                    subscribeButton
                    trialDisclaimer
                    footerLinks
                    dismissButton
                }
            }
            .scrollIndicators(.hidden)
            .refreshable {
                isLoadingProducts = true
                await subscriptionManager.loadProducts()
                isLoadingProducts = false
                if let err = subscriptionManager.purchaseError {
                    errorMessage = err
                    subscriptionManager.purchaseError = nil
                }
            }
        }
        .overlay {
            if isLoading || isLoadingProducts {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView(isLoadingProducts ? "Loading subscription options..." : "Processing...")
                        .padding(24)
                        .background(.regularMaterial)
                        .clipShape(.rect(cornerRadius: 12))
                }
            }
        }
        .alert("Error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            isLoadingProducts = true
            await subscriptionManager.loadProducts()
            isLoadingProducts = false

            if let err = subscriptionManager.purchaseError {
                errorMessage = err
                subscriptionManager.purchaseError = nil
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.92))
                    .frame(width: 104, height: 104)
                    .shadow(color: Theme.medicalBlue.opacity(0.12), radius: 20, y: 10)
                Circle()
                    .stroke(Theme.primaryGradient, lineWidth: 2.5)
                    .frame(width: 104, height: 104)
                Image(systemName: "shield.checkered")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.medicalBlue)
            }
            .padding(.top, 20)

            Text("Protect your career")
                .font(.title.bold())
                .foregroundStyle(Theme.headerText)

            Text("A license lapse costs $5,000–$50,000+ in lost income.\nMedCertify costs less than one patient visit.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Plan Selector

    private var planSelector: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(duration: 0.2)) { selectedPlan = .annual }
            } label: {
                VStack(spacing: 0) {
                    HStack {
                        Text("BEST VALUE")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.credentialGold)
                            .clipShape(.capsule)
                        Spacer()
                    }
                    .padding(.bottom, 10)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Annual")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("7-day free trial included")
                                .font(.caption)
                                .foregroundStyle(Theme.statusGreen)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            if let product = subscriptionManager.annualProduct {
                                Text(product.displayPrice + "/year")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.primary)
                            } else {
                                Text("$49.99/year")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.primary)
                            }
                            Text("$4.17/month • Save 58%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(
                    selectedPlan == .annual
                        ? Theme.medicalBlue.opacity(0.08)
                        : Theme.surfaceMuted
                )
                .clipShape(.rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            selectedPlan == .annual ? Theme.medicalBlue : Theme.subtleBorder,
                            lineWidth: selectedPlan == .annual ? 2 : 1
                        )
                )
            }

            Button {
                withAnimation(.spring(duration: 0.2)) { selectedPlan = .monthly }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("No free trial")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        if let product = subscriptionManager.monthlyProduct {
                            Text(product.displayPrice + "/month")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                        } else {
                            Text("$9.99/month")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                        }
                        Text("$119.88/year")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .background(
                    selectedPlan == .monthly
                        ? Theme.medicalBlue.opacity(0.08)
                        : Theme.surfaceMuted
                )
                .clipShape(.rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            selectedPlan == .monthly ? Theme.medicalBlue : Theme.subtleBorder,
                            lineWidth: selectedPlan == .monthly ? 2 : 1
                        )
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
    }

    // MARK: - Subscribe Button

    private var selectedProductReady: Bool {
        if !SubscriptionManager.subscriptionsOfferedInApp { return true }
        switch selectedPlan {
        case .annual:
            return subscriptionManager.annualProduct != nil
        case .monthly:
            return subscriptionManager.monthlyProduct != nil
        }
    }

    private var subscribeButton: some View {
        Button {
            Task { await handlePurchase() }
        } label: {
            Text(selectedPlan == .annual ? "Start Free Trial" : "Subscribe")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.medicalBlue)
        .disabled(isLoading || isLoadingProducts || !selectedProductReady)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .sensoryFeedback(.success, trigger: selectedPlan)
    }

    // MARK: - Trial Disclaimer

    @ViewBuilder
    private var trialDisclaimer: some View {
        if selectedPlan == .annual {
            Text("Your free trial starts today. You'll be charged \(subscriptionManager.annualProduct?.displayPrice ?? "$49.99") on \(trialEndDate) unless you cancel. Cancel anytime in Settings.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 12)
        }
    }

    // MARK: - Footer

    private var footerLinks: some View {
        HStack(spacing: 16) {
            Button("Restore Purchases") {
                Task { await handleRestore() }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .disabled(isLoading || isLoadingProducts)

            Text("•").foregroundStyle(.secondary)

            Link("Terms of Service", destination: URL(string: Constants.termsURL)!)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("•").foregroundStyle(.secondary)

            Link("Privacy Policy", destination: URL(string: Constants.privacyURL)!)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 16)
    }

    private var dismissButton: some View {
        Button {
            onDismiss()
        } label: {
            Text("Not now")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
        .padding(.bottom, 32)
    }

    // MARK: - Actions

    private func handlePurchase() async {
        isLoading = true

        if selectedPlan == .annual {
            await subscriptionManager.purchaseAnnual()
        } else {
            await subscriptionManager.purchaseMonthly()
        }

        isLoading = false

        if let error = subscriptionManager.purchaseError {
            errorMessage = error
        } else if subscriptionManager.isPro {
            // Schedule trial end reminder for annual plan
            if selectedPlan == .annual {
                await NotificationManager.shared.scheduleTrialEndReminder()
            }
            onSubscribe()
        }
    }

    private func handleRestore() async {
        isLoading = true
        await subscriptionManager.restorePurchases()
        isLoading = false

        if let error = subscriptionManager.purchaseError {
            errorMessage = error
        } else if subscriptionManager.isPro {
            onSubscribe()
        } else {
            errorMessage = "No active subscription found."
        }
    }
}
