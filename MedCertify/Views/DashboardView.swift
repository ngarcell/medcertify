import SwiftUI
import SwiftData

struct DashboardView: View {
    let credentialVM: CredentialViewModel
    let cmeVM: CMEViewModel

    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(sort: \Credential.expirationDate) private var credentials: [Credential]
    @Query(sort: \CMEActivity.dateCompleted, order: .reverse) private var activities: [CMEActivity]
    @Query(sort: \CredentialDocument.uploadDate, order: .reverse) private var documents: [CredentialDocument]
    @Query private var cycles: [CMECycle]
    @Query private var profiles: [UserProfile]

    @State private var showAddCredential: Bool = false
    @State private var showAddCME: Bool = false
    @State private var showPaywall: Bool = false
    @State private var showScanner: Bool = false
    @State private var showSettings: Bool = false

    private var profile: UserProfile? {
        profiles.first
    }

    private var sortedCredentials: [Credential] {
        credentialVM.prioritySorted(credentials)
    }

    private var attentionCredentials: [Credential] {
        credentialVM.attentionCredentials(credentials)
    }

    private var mostUrgentCredential: Credential? {
        attentionCredentials.first ?? sortedCredentials.first
    }

    private var recentProof: [CredentialDocument] {
        Array(documents.prefix(3))
    }

    private var compliancePercentage: Int {
        credentialVM.compliancePercentage(credentials)
    }

    private var credentialsWithProofCount: Int {
        credentials.filter { credential in
            documents.contains { $0.linkedCredentialId == credential.id }
        }.count
    }

    private var educationLabel: String {
        profile?.educationTabTitle ?? "CME"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    topIdentityBar
                    focusSection
                    readinessSection
                    quickActionsSection
                    proofSection
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 110)
            }
            .background(Theme.canvasGradient)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                Button {
                    if subscriptionManager.checkCredentialLimit(currentCount: credentials.count) {
                        showAddCredential = true
                    } else {
                        subscriptionManager.triggerPaywall(reason: "Upgrade to track more than \(Constants.maxFreeCredentials) credentials.")
                        showPaywall = true
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus")
                            .font(.headline.weight(.bold))
                        Text("Add credential")
                            .font(Theme.ui(17, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Theme.primaryGradient, in: RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .background(.bar)
                }
                .buttonStyle(.plain)
            }
            .sheet(isPresented: $showAddCredential) {
                AddCredentialView(viewModel: credentialVM)
            }
            .sheet(isPresented: $showAddCME) {
                AddCMEActivityView(viewModel: cmeVM)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    onDismiss: { showPaywall = false },
                    onSubscribe: { showPaywall = false }
                )
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                }
            }
            .fullScreenCover(isPresented: $showScanner) {
                DocumentScannerView(
                    onScanComplete: { data, fileName in
                        let document = CredentialDocument(
                            fileName: fileName,
                            fileType: "pdf",
                            fileData: data,
                            tags: ["scanned"],
                            notes: nil
                        )
                        modelContext.insert(document)
                        try? modelContext.save()
                        showScanner = false
                    },
                    onCancel: { showScanner = false }
                )
                .ignoresSafeArea()
            }
        }
    }

    private var topIdentityBar: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("MedCertify")
                    .font(Theme.ui(12, weight: .semibold))
                    .tracking(2.2)
                    .foregroundStyle(Theme.copper)

                Text("\(profile?.firstNameOrFallback ?? "Welcome"), here’s your credential desk.")
                    .font(Theme.display(33, relativeTo: .largeTitle, prominent: true))
                    .foregroundStyle(Theme.headerText)

                Text(profile?.workflowSourceLabel ?? "Bring renewals, proof, and deadlines into one place.")
                    .font(Theme.ui(15))
                    .foregroundStyle(Theme.mutedLabel)
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                VStack(spacing: 6) {
                    Text(profile?.initials ?? "MC")
                        .font(Theme.ui(15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Theme.primaryGradient, in: Circle())

                    Text(profile?.shortProfession ?? "Account")
                        .font(Theme.ui(11, weight: .medium))
                        .foregroundStyle(Theme.mutedLabel)
                        .lineLimit(1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open account and settings")
        }
    }

    @ViewBuilder
    private var focusSection: some View {
        if let credential = mostUrgentCredential {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(title: "Front and center", subtitle: "The next item that deserves your attention.")

                NavigationLink {
                    CredentialDetailView(credential: credential, viewModel: credentialVM)
                } label: {
                    UrgentCredentialHero(
                        credential: credential,
                        linkedProofCount: linkedProofCount(for: credential)
                    )
                }
                .buttonStyle(.plain)

                if attentionCredentials.count > 1 {
                    VStack(spacing: 10) {
                        ForEach(Array(attentionCredentials.dropFirst().prefix(2))) { credential in
                            NavigationLink {
                                CredentialDetailView(credential: credential, viewModel: credentialVM)
                            } label: {
                                HomeAttentionRow(
                                    credential: credential,
                                    linkedProofCount: linkedProofCount(for: credential)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title: "Front and center", subtitle: "Everything is quiet right now.")

                VStack(alignment: .leading, spacing: 12) {
                    Text("Start with the credentials you never want to track in your head again.")
                        .font(Theme.ui(16))
                        .foregroundStyle(Theme.bodyText)

                    Text("Add your core licenses first, then layer in certificates and proof.")
                        .font(Theme.ui(14))
                        .foregroundStyle(Theme.mutedLabel)
                }
                .padding(Theme.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusLarge))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.radiusLarge)
                        .stroke(Theme.subtleBorder, lineWidth: 1)
                }
            }
        }
    }

    private var readinessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Readiness", subtitle: "A quick view of coverage, proof, and education progress.")

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    HomeMetricCard(title: "Compliance", value: "\(compliancePercentage)%", caption: credentials.isEmpty ? "No credentials yet" : "\(credentials.count) tracked")
                    HomeMetricCard(title: "Licensed footprint", value: "\(profile?.selectedStates.count ?? 0)", caption: profile?.licensedStateSummary ?? "Add states")
                }

                HStack(spacing: 12) {
                    HomeMetricCard(title: "Proof coverage", value: "\(credentialsWithProofCount)", caption: credentials.isEmpty ? "Link proof later" : "Credentials with proof")
                    if subscriptionManager.isPro, let cycle = cycles.first {
                        EducationProgressCard(
                            title: profile?.educationProgressTitle ?? "\(educationLabel) Progress",
                            value: educationProgressValue(cycle: cycle),
                            caption: educationProgressCaption(cycle: cycle)
                        )
                    } else {
                        HomeMetricCard(title: educationLabel, value: subscriptionManager.isPro ? "0" : "Pro", caption: subscriptionManager.isPro ? "Set up a cycle" : "Unlock progress tracking")
                    }
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Quick capture", subtitle: "The actions clinicians usually need in the moment.")

            HStack(spacing: 12) {
                HomeQuickActionCard(
                    title: "Add credential",
                    subtitle: "New license, certification, or renewal",
                    icon: "plus.circle",
                    tint: Theme.inkAccent
                ) {
                    if subscriptionManager.checkCredentialLimit(currentCount: credentials.count) {
                        showAddCredential = true
                    } else {
                        showPaywall = true
                    }
                }

                HomeQuickActionCard(
                    title: "Log \(educationLabel)",
                    subtitle: "Keep credits recorded before they pile up",
                    icon: "book.closed",
                    tint: Theme.coolAccent
                ) {
                    if subscriptionManager.isPro {
                        showAddCME = true
                    } else {
                        showPaywall = true
                    }
                }
            }

            HomeQuickActionCard(
                title: "Scan proof",
                subtitle: subscriptionManager.isPro ? "Add a renewal or certificate to your vault" : "Unlock secure proof capture in the vault",
                icon: "doc.viewfinder",
                tint: Theme.copper
            ) {
                if subscriptionManager.isPro {
                    showScanner = true
                } else {
                    showPaywall = true
                }
            }
        }
    }

    private var proofSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Recent proof", subtitle: subscriptionManager.isPro ? "The last documents added to your vault." : "Vault access is part of the premium workflow.")

            if !subscriptionManager.isPro {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Upgrade when you want a cleaner record of certificates, confirmations, and scanned paperwork.")
                        .font(Theme.ui(15))
                        .foregroundStyle(Theme.bodyText)

                    Button("View premium access") {
                        showPaywall = true
                    }
                    .font(Theme.ui(15, weight: .semibold))
                    .foregroundStyle(Theme.inkAccent)
                }
                .padding(Theme.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusLarge))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.radiusLarge)
                        .stroke(Theme.subtleBorder, lineWidth: 1)
                }
            } else if recentProof.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your vault is empty.")
                        .font(Theme.ui(17, weight: .semibold))
                        .foregroundStyle(Theme.bodyText)
                    Text("Scan a certificate or import a file so the next renewal has proof attached.")
                        .font(Theme.ui(14))
                        .foregroundStyle(Theme.mutedLabel)
                }
                .padding(Theme.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusLarge))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.radiusLarge)
                        .stroke(Theme.subtleBorder, lineWidth: 1)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(recentProof) { document in
                        RecentProofRow(document: document, linkedCredential: credentials.first(where: { $0.id == document.linkedCredentialId }))
                    }
                }
            }
        }
    }

    private func linkedProofCount(for credential: Credential) -> Int {
        documents.filter { $0.linkedCredentialId == credential.id }.count
    }

    private func educationProgressValue(cycle: CMECycle) -> String {
        let cycleActivities = cmeVM.activitiesForCycle(activities, cycle: cycle)
        let totalHours = cmeVM.totalHours(cycleActivities)
        return "\(Int(totalHours.rounded()))/\(Int(cycle.totalHoursRequired.rounded()))"
    }

    private func educationProgressCaption(cycle: CMECycle) -> String {
        let cycleActivities = cmeVM.activitiesForCycle(activities, cycle: cycle)
        let totalHours = cmeVM.totalHours(cycleActivities)
        let remaining = max(0, Int((cycle.totalHoursRequired - totalHours).rounded()))
        return remaining == 0 ? "Cycle on pace" : "\(remaining) left this cycle"
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Theme.ui(13, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Theme.copper)
            Text(subtitle)
                .font(Theme.ui(14))
                .foregroundStyle(Theme.mutedLabel)
        }
    }
}

private struct UrgentCredentialHero: View {
    let credential: Credential
    let linkedProofCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(credential.status.rawValue.uppercased())
                        .font(Theme.ui(12, weight: .semibold))
                        .tracking(1.8)
                        .foregroundStyle(Theme.statusColor(for: credential.status))

                    Text(credential.displayName)
                        .font(Theme.display(28, relativeTo: .title, prominent: true))
                        .foregroundStyle(Theme.headerText)

                    Text(credential.metaLine)
                        .font(Theme.ui(15))
                        .foregroundStyle(Theme.mutedLabel)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(credential.dueStatusText)
                        .font(Theme.ui(16, weight: .semibold))
                        .foregroundStyle(Theme.headerText)
                    Text(credential.expirationDisplay)
                        .font(Theme.ui(13))
                        .foregroundStyle(Theme.mutedLabel)
                }
            }

            HStack(spacing: 12) {
                heroPill(title: "Checklist", value: "\(credential.checklistItems.filter(\.completed).count)/\(credential.checklistItems.count)")
                heroPill(title: "Proof", value: linkedProofCount == 0 ? "Missing" : "\(linkedProofCount) linked")
            }
        }
        .padding(Theme.cardPadding)
        .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.radiusLarge)
                .stroke(Theme.statusColor(for: credential.status).opacity(0.22), lineWidth: 1.5)
        }
    }

    private func heroPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(Theme.ui(11, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(Theme.mutedLabel)
            Text(value)
                .font(Theme.ui(15, weight: .semibold))
                .foregroundStyle(Theme.bodyText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surfaceMuted.opacity(0.7), in: RoundedRectangle(cornerRadius: Theme.radiusSmall))
    }
}

private struct HomeAttentionRow: View {
    let credential: Credential
    let linkedProofCount: Int

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.statusColor(for: credential.status).opacity(0.14))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: credential.credentialType.icon)
                        .foregroundStyle(Theme.statusColor(for: credential.status))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(credential.displayName)
                    .font(Theme.ui(16, weight: .semibold))
                    .foregroundStyle(Theme.bodyText)
                Text("\(credential.dueStatusText) • \(linkedProofCount == 0 ? "Proof missing" : "\(linkedProofCount) proof linked")")
                    .font(Theme.ui(13))
                    .foregroundStyle(Theme.mutedLabel)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.mutedLabel)
        }
        .padding(16)
        .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .stroke(Theme.subtleBorder, lineWidth: 1)
        }
    }
}

private struct HomeMetricCard: View {
    let title: String
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(Theme.ui(11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.mutedLabel)
            Text(value)
                .font(Theme.display(28, relativeTo: .title2, prominent: true))
                .foregroundStyle(Theme.headerText)
            Text(caption)
                .font(Theme.ui(13))
                .foregroundStyle(Theme.mutedLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.cardPadding)
        .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .stroke(Theme.subtleBorder, lineWidth: 1)
        }
    }
}

private struct EducationProgressCard: View {
    let title: String
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(Theme.ui(11, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(Theme.mutedLabel)
            Text(value)
                .font(Theme.display(26, relativeTo: .title2, prominent: true))
                .foregroundStyle(Theme.headerText)
            Text(caption)
                .font(Theme.ui(13))
                .foregroundStyle(Theme.mutedLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.cardPadding)
        .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .stroke(Theme.coolAccent.opacity(0.18), lineWidth: 1.2)
        }
    }
}

private struct HomeQuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(tint.opacity(0.14))
                    .frame(width: 46, height: 46)
                    .overlay {
                        Image(systemName: icon)
                            .font(.headline)
                            .foregroundStyle(tint)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Theme.ui(16, weight: .semibold))
                        .foregroundStyle(Theme.bodyText)
                    Text(subtitle)
                        .font(Theme.ui(13))
                        .foregroundStyle(Theme.mutedLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
            }
            .padding(16)
            .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                    .stroke(Theme.subtleBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct RecentProofRow: View {
    let document: CredentialDocument
    let linkedCredential: Credential?

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.inkAccent.opacity(0.1))
                .frame(width: 46, height: 46)
                .overlay {
                    Image(systemName: document.iconName)
                        .foregroundStyle(Theme.inkAccent)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(document.fileName)
                    .font(Theme.ui(16, weight: .semibold))
                    .foregroundStyle(Theme.bodyText)
                    .lineLimit(1)
                Text(linkedCredential?.displayName ?? "Unlinked proof")
                    .font(Theme.ui(13))
                    .foregroundStyle(Theme.mutedLabel)
            }

            Spacer()

            Text(document.uploadDate.formatted(.dateTime.month(.abbreviated).day()))
                .font(Theme.ui(12, weight: .medium))
                .foregroundStyle(Theme.mutedLabel)
        }
        .padding(16)
        .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .stroke(Theme.subtleBorder, lineWidth: 1)
        }
    }
}
