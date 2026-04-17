import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Int = 0
    @State private var credentialVM: CredentialViewModel?
    @State private var cmeVM: CMEViewModel?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "square.grid.2x2.fill", value: 0) {
                DashboardView(credentialVM: resolvedCredentialVM, cmeVM: resolvedCMEVM)
            }
            Tab("Credentials", systemImage: "checkmark.shield.fill", value: 1) {
                CredentialsListView(viewModel: resolvedCredentialVM)
            }
            Tab("CME", systemImage: "clipboard.text.fill", value: 2) {
                CMELogView(viewModel: resolvedCMEVM)
            }
            Tab("Docs", systemImage: "folder.badge.person.crop", value: 3) {
                DocumentsView()
            }
            Tab("Profile", systemImage: "person.crop.circle", value: 4) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tint(Theme.medicalBlue)
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
