import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var selectedTab: Int = 0
    @State private var credentialVM: CredentialViewModel?
    @State private var cmeVM: CMEViewModel?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "shield.checkered", value: 0) {
                DashboardView(credentialVM: resolvedCredentialVM, cmeVM: resolvedCMEVM)
            }
            Tab("Credentials", systemImage: "doc.text.fill", value: 1) {
                CredentialsListView(viewModel: resolvedCredentialVM)
            }
            Tab("CME Log", systemImage: "book.fill", value: 2) {
                CMELogView(viewModel: resolvedCMEVM)
            }
            Tab("Documents", systemImage: "folder.fill", value: 3) {
                DocumentsView()
            }
            Tab("Settings", systemImage: "gearshape.fill", value: 4) {
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
