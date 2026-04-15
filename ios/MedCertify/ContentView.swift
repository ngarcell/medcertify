import SwiftUI
import SwiftData
import LocalAuthentication

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled: Bool = true
    @Query private var profiles: [UserProfile]
    @State private var isUnlocked: Bool = false
    @State private var authenticationFailed: Bool = false

    private var isOnboarded: Bool {
        hasCompletedOnboarding || profiles.contains(where: \.onboardingComplete)
    }

    var body: some View {
        Group {
            if isOnboarded {
                if biometricLockEnabled && !isUnlocked {
                    lockScreen
                } else {
                    MainTabView()
                }
            } else {
                OnboardingContainerView(onboardingComplete: $hasCompletedOnboarding)
            }
        }
        .animation(.spring(duration: 0.5), value: isOnboarded)
        .animation(.spring(duration: 0.3), value: isUnlocked)
        .onAppear {
            if biometricLockEnabled && isOnboarded {
                authenticate()
            } else {
                isUnlocked = true
            }
        }
    }

    // MARK: - Lock Screen

    private var lockScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Text("MedCertify")
                    .font(Theme.ui(13, weight: .semibold))
                    .tracking(2.4)
                    .foregroundStyle(Theme.copper)

                Text("Your credential desk is locked.")
                    .font(Theme.display(34, relativeTo: .largeTitle, prominent: true))
                    .foregroundStyle(Theme.headerText)
                    .multilineTextAlignment(.center)

                Text("Authenticate to review renewals, proof, and upcoming deadlines.")
                    .font(Theme.ui(16))
                    .foregroundStyle(Theme.mutedLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                authenticate()
            } label: {
                Image(systemName: biometricIconName)
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(Theme.primaryGradient)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Unlock with \(biometricTypeName)")

            if authenticationFailed {
                Text("Authentication failed. Tap to try again.")
                    .font(.caption)
                    .foregroundStyle(Theme.statusRed)
                    .transition(.opacity)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.canvasGradient.ignoresSafeArea())
    }

    // MARK: - Authentication

    private func authenticate() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock MedCertify to access your credentials"
            ) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        withAnimation {
                            isUnlocked = true
                            authenticationFailed = false
                        }
                    } else {
                        withAnimation {
                            authenticationFailed = true
                        }
                    }
                }
            }
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            // Fallback to passcode
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock MedCertify to access your credentials"
            ) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        withAnimation {
                            isUnlocked = true
                            authenticationFailed = false
                        }
                    } else {
                        withAnimation {
                            authenticationFailed = true
                        }
                    }
                }
            }
        } else {
            // No authentication available — unlock directly
            isUnlocked = true
        }
    }

    private var biometricTypeName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Passcode"
        }
    }

    private var biometricIconName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.fill"
        }
    }
}
