import SwiftUI
import SwiftData
import StoreKit
import LocalAuthentication
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.requestReview) private var requestReview
    @Query private var profiles: [UserProfile]
    @Query private var credentials: [Credential]

    @AppStorage("biometricLockEnabled") private var biometricLockEnabled: Bool = true
    @AppStorage("notifications_enabled") private var notificationsEnabled: Bool = true

    @State private var showPaywall: Bool = false
    @State private var showExportSheet: Bool = false
    @State private var exportURL: URL?
    @State private var showDeleteConfirmation: Bool = false
    @State private var exportError: String?

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        List {
            profileSection
            subscriptionSection
            securitySection
            dataSection
            aboutSection
            disclaimerSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                onDismiss: { showPaywall = false },
                onSubscribe: { showPaywall = false }
            )
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Export Error", isPresented: .init(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK") { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section("Profile") {
            if let profile = profile {
                HStack(spacing: 14) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.medicalBlue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.profession.isEmpty ? "Healthcare Professional" : profile.profession)
                            .font(.body.weight(.medium))
                        Text("Licensed in \(profile.selectedStates.count) state\(profile.selectedStates.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)

                HStack {
                    Text("Credentials tracked")
                        .font(.subheadline)
                    Spacer()
                    if subscriptionManager.isPro {
                        Text("\(credentials.count)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.medicalBlue)
                    } else {
                        Text("\(credentials.count) / \(Constants.maxFreeCredentials)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(credentials.count >= Constants.maxFreeCredentials ? Theme.statusAmber : Theme.medicalBlue)
                    }
                }
            }
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        Group {
            if !SubscriptionManager.subscriptionsOfferedInApp {
                Section("Subscription") {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Theme.medicalBlue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Full app access")
                                .font(.body.weight(.semibold))
                            Text("This release includes all features at no charge. Paid subscriptions may be added in a future update.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Section("Subscription") {
                    if subscriptionManager.isPro {
                        HStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(Theme.credentialGold)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("MedCertify Pro")
                                    .font(.body.weight(.semibold))
                                Text("All features unlocked")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("Active")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.statusGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.statusGreen.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 4)

                        Button("Manage Subscription") {
                            Task {
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    try? await AppStore.showManageSubscriptions(in: windowScene)
                                }
                            }
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(Theme.credentialGold)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Upgrade to Pro")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text("Unlimited credentials, reminders, CME tracking")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button("Restore Purchases") {
                            Task {
                                await subscriptionManager.restorePurchases()
                            }
                        }
                        .foregroundStyle(Theme.medicalBlue)
                    }
                }
            }
        }
    }

    // MARK: - Security

    private var securitySection: some View {
        Section {
            Toggle(isOn: $biometricLockEnabled) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(biometricTypeName)
                        Text("Require authentication to open MedCertify")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: biometricIconName)
                }
            }
            .tint(Theme.medicalBlue)

            Toggle(isOn: $notificationsEnabled) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Renewal Reminders")
                        Text("Get notified months before expiration")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "bell.badge.fill")
                }
            }
            .tint(Theme.medicalBlue)
            .onChange(of: notificationsEnabled) { _, enabled in
                if enabled {
                    Task {
                        _ = await NotificationManager.shared.requestAuthorization()
                        NotificationManager.shared.refreshAllReminders(for: credentials)
                    }
                }
            }
        } header: {
            Text("Security & Notifications")
        } footer: {
            Text("All credential data is encrypted at rest via iOS Data Protection. No data is sent to external servers.")
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section("Data") {
            Button {
                generateAndExport()
            } label: {
                Label("Export Credential Summary", systemImage: "square.and.arrow.up")
            }
            .disabled(!subscriptionManager.isPro)

            if !subscriptionManager.isPro {
                Text("Export requires Pro subscription")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete All Data", systemImage: "trash.fill")
                    .foregroundStyle(.red)
            }
        }
    }

    private func generateAndExport() {
        let profileName = profile?.profession
        let pdfData = PDFExporter.generateCredentialSummary(
            credentials: credentials,
            profileName: profileName
        )

        if let url = PDFExporter.saveTempPDF(data: pdfData) {
            exportURL = url
            showExportSheet = true
        } else {
            exportError = "Failed to generate PDF. Please try again."
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundStyle(.secondary)
            }

            Button {
                requestReview()
            } label: {
                Label("Rate MedCertify", systemImage: "star.fill")
            }

            Link(destination: URL(string: "mailto:\(Constants.supportEmail)")!) {
                Label("Contact Support", systemImage: "envelope.fill")
            }

            Link(destination: URL(string: Constants.privacyURL)!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }

            Link(destination: URL(string: Constants.termsURL)!) {
                Label("Terms of Service", systemImage: "doc.plaintext.fill")
            }
        }
    }

    // MARK: - Disclaimer

    private var disclaimerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Important Disclosure")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text("MedCertify is a personal organization tool. It is not an official credential verification system and does not guarantee compliance. Always verify directly with licensing boards and accrediting bodies. This app does not collect or store patient health data.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .confirmationDialog(
            "Delete All Data?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your credentials, documents, CME activities, and profile data. This cannot be undone.")
        }
    }

    private func deleteAllData() {
        // Delete all model objects
        do {
            try modelContext.delete(model: Credential.self)
            try modelContext.delete(model: CredentialDocument.self)
            try modelContext.delete(model: CMEActivity.self)
            try modelContext.delete(model: CMECycle.self)
            try modelContext.delete(model: ChecklistItem.self)
            try modelContext.delete(model: RenewalHistory.self)
            try modelContext.delete(model: UserProfile.self)
            try modelContext.save()
        } catch {
            print("Failed to delete data: \(error)")
        }

        // Cancel all pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Helpers

    private var biometricTypeName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Passcode Lock"
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
