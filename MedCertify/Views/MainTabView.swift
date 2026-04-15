import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var selectedTab: Int = 0
    @State private var credentialVM: CredentialViewModel?
    @State private var cmeVM: CMEViewModel?

    private var profile: UserProfile? {
        profiles.first
    }

    private var educationTabTitle: String {
        profile?.educationTabTitle ?? "CME"
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "square.grid.2x2.fill", value: 0) {
                DashboardView(credentialVM: resolvedCredentialVM, cmeVM: resolvedCMEVM)
            }
            Tab("Credentials", systemImage: "checkmark.shield.fill", value: 1) {
                CredentialsListView(viewModel: resolvedCredentialVM)
            }
            Tab(educationTabTitle, systemImage: "clipboard.text.fill", value: 2) {
                CMELogView(viewModel: resolvedCMEVM)
            }
            Tab("Vault", systemImage: "folder.badge.person.crop", value: 3) {
                DocumentsView()
            }
        }
        .tint(Theme.inkAccent)
        .onAppear {
            if credentialVM == nil {
                credentialVM = CredentialViewModel(modelContext: modelContext)
            }
            if cmeVM == nil {
                cmeVM = CMEViewModel(modelContext: modelContext)
            }
        }
    }

    private var resolvedCredentialVM: CredentialViewModel {
        credentialVM ?? CredentialViewModel(modelContext: modelContext)
    }

    private var resolvedCMEVM: CMEViewModel {
        cmeVM ?? CMEViewModel(modelContext: modelContext)
    }
}
