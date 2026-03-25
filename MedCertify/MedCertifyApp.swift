import SwiftUI
import SwiftData

@main
struct MedCertifyApp: App {
    @State private var subscriptionManager = SubscriptionManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Credential.self,
            ChecklistItem.self,
            RenewalHistory.self,
            CMEActivity.self,
            CMECycle.self,
            CredentialDocument.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(subscriptionManager)
                .task {
                    subscriptionManager.listenForTransactions()
                    if SubscriptionManager.subscriptionsOfferedInApp {
                        await subscriptionManager.loadProducts()
                    }
                    await subscriptionManager.updateSubscriptionStatus()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
