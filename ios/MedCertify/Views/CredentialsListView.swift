import SwiftUI
import SwiftData

private enum CredentialFilter: String, CaseIterable, Identifiable {
    case actionNeeded = "Action Needed"
    case current = "Current"
    case noDeadline = "No Deadline"

    var id: String { rawValue }
}

struct CredentialsListView: View {
    let viewModel: CredentialViewModel
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(sort: \Credential.expirationDate) private var credentials: [Credential]
    @Query(sort: \CredentialDocument.uploadDate, order: .reverse) private var documents: [CredentialDocument]
    @State private var showAddCredential: Bool = false
    @State private var showPaywall: Bool = false
    @State private var searchText: String = ""
    @State private var selectedFilter: CredentialFilter = .actionNeeded

    private var filteredCredentials: [Credential] {
        let searched = viewModel.prioritySorted(credentials).filter { credential in
            if searchText.isEmpty { return true }
            return credential.displayName.localizedStandardContains(searchText)
                || credential.credentialType.rawValue.localizedStandardContains(searchText)
                || credential.issuingBody.localizedStandardContains(searchText)
                || (credential.state ?? "").localizedStandardContains(searchText)
                || (credential.credentialNumber ?? "").localizedStandardContains(searchText)
        }

        return searched.filter { credential in
            switch selectedFilter {
            case .actionNeeded:
                return credential.status == .expired || credential.status == .expiringSoon || credential.status == .pending
            case .current:
                return credential.status == .current && credential.expirationDate != nil
            case .noDeadline:
                return credential.expirationDate == nil
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    filterBar
                    contentSection
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
            .background(Theme.canvasGradient)
            .searchable(text: $searchText, prompt: "Search credentials")
            .navigationTitle("Credentials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if subscriptionManager.checkCredentialLimit(currentCount: credentials.count) {
                            showAddCredential = true
                        } else {
                            subscriptionManager.triggerPaywall(reason: "Upgrade to track more than \(Constants.maxFreeCredentials) credentials.")
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.inkAccent)
                    }
                }
            }
            .sheet(isPresented: $showAddCredential) {
                AddCredentialView(viewModel: viewModel)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    onDismiss: { showPaywall = false },
                    onSubscribe: { showPaywall = false }
                )
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Urgency-first credential tracking so the next board request is easier to answer.")
                .font(Theme.ui(15))
                .foregroundStyle(Theme.mutedLabel)

            if !subscriptionManager.isPro && credentials.count >= Constants.maxFreeCredentials {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.copper.opacity(0.14))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: "crown")
                                    .foregroundStyle(Theme.copper)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Free plan limit reached")
                                .font(Theme.ui(16, weight: .semibold))
                                .foregroundStyle(Theme.bodyText)
                            Text("\(credentials.count)/\(Constants.maxFreeCredentials) tracked. Upgrade when you need more room.")
                                .font(Theme.ui(13))
                                .foregroundStyle(Theme.mutedLabel)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(Theme.mutedLabel)
                    }
                    .padding(16)
                    .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusMedium))
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.radiusMedium)
                            .stroke(Theme.copper.opacity(0.22), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CredentialFilter.allCases) { filter in
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(Theme.ui(14, weight: .semibold))
                            .foregroundStyle(selectedFilter == filter ? .white : Theme.bodyText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(selectedFilter == filter ? Theme.primaryGradient : LinearGradient(colors: [Theme.surfaceCard], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(selectedFilter == filter ? Color.clear : Theme.subtleBorder, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        if credentials.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("No credentials yet")
                    .font(Theme.display(28, relativeTo: .title2, prominent: true))
                    .foregroundStyle(Theme.headerText)
                Text("Add the licenses and certifications you never want to track from memory again.")
                    .font(Theme.ui(15))
                    .foregroundStyle(Theme.mutedLabel)
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusLarge))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.radiusLarge)
                    .stroke(Theme.subtleBorder, lineWidth: 1)
            }
        } else if filteredCredentials.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Nothing matches this view.")
                    .font(Theme.ui(16, weight: .semibold))
                    .foregroundStyle(Theme.bodyText)
                Text("Try another filter or search term.")
                    .font(Theme.ui(14))
                    .foregroundStyle(Theme.mutedLabel)
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                    .stroke(Theme.subtleBorder, lineWidth: 1)
            }
        } else {
            LazyVStack(spacing: 12) {
                ForEach(filteredCredentials) { credential in
                    NavigationLink {
                        CredentialDetailView(credential: credential, viewModel: viewModel)
                    } label: {
                        CredentialPriorityCard(
                            credential: credential,
                            linkedProofCount: documents.filter { $0.linkedCredentialId == credential.id }.count
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct CredentialPriorityCard: View {
    let credential: Credential
    let linkedProofCount: Int

    private var checklistProgress: String {
        "\(credential.checklistItems.filter(\.completed).count)/\(credential.checklistItems.count)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.statusColor(for: credential.status).opacity(0.14))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: credential.credentialType.icon)
                            .font(.headline)
                            .foregroundStyle(Theme.statusColor(for: credential.status))
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(credential.displayName)
                        .font(Theme.ui(17, weight: .semibold))
                        .foregroundStyle(Theme.bodyText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(credential.metaLine)
                        .font(Theme.ui(13))
                        .foregroundStyle(Theme.mutedLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(credential.secondaryMetaLine)
                        .font(Theme.ui(12, weight: .medium))
                        .foregroundStyle(Theme.mutedLabel)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.mutedLabel)
            }

            HStack(spacing: 10) {
                cardPill(title: credential.status.rawValue, value: credential.dueStatusText, tint: Theme.statusColor(for: credential.status))
                cardPill(title: "Checklist", value: checklistProgress, tint: Theme.coolAccent)
                cardPill(title: "Proof", value: linkedProofCount == 0 ? "Missing" : "\(linkedProofCount) linked", tint: Theme.copper)
            }
        }
        .padding(Theme.cardPadding)
        .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.radiusLarge)
                .stroke(Theme.subtleBorder, lineWidth: 1)
        }
    }

    private func cardPill(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(Theme.ui(11, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(tint)
            Text(value)
                .font(Theme.ui(13, weight: .semibold))
                .foregroundStyle(Theme.bodyText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.surfaceMuted.opacity(0.6), in: RoundedRectangle(cornerRadius: Theme.radiusSmall))
    }
}
