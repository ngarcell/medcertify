import SwiftUI
import SwiftData

struct CredentialsListView: View {
    let viewModel: CredentialViewModel
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(sort: \Credential.expirationDate) private var credentials: [Credential]
    @State private var showAddCredential: Bool = false
    @State private var showPaywall: Bool = false
    @State private var searchText: String = ""

    private var groupedCredentials: [(String, [Credential])] {
        let filtered: [Credential]
        if searchText.isEmpty {
            filtered = credentials
        } else {
            filtered = credentials.filter {
                $0.name.localizedStandardContains(searchText) ||
                $0.credentialType.rawValue.localizedStandardContains(searchText) ||
                ($0.state ?? "").localizedStandardContains(searchText)
            }
        }
        return viewModel.credentialsByCategory(filtered)
    }

    var body: some View {
        NavigationStack {
            List {
                if !subscriptionManager.isPro && credentials.count >= Constants.maxFreeCredentials {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(Theme.credentialGold)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Free Limit Reached")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text("\(credentials.count)/\(Constants.maxFreeCredentials) credentials used. Upgrade for unlimited.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .listRowBackground(Theme.credentialGold.opacity(0.08))
                }

                if credentials.isEmpty {
                    ContentUnavailableView {
                        Label("No Credentials", systemImage: "doc.text")
                    } description: {
                        Text("Tap + to add your first credential.")
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(groupedCredentials, id: \.0) { category, items in
                        Section(category) {
                            ForEach(items) { credential in
                                NavigationLink(value: credential.id) {
                                    CredentialRow(credential: credential)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.deleteCredential(credential)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search credentials")
            .navigationTitle("Credentials")
            .navigationDestination(for: UUID.self) { credentialId in
                if let credential = credentials.first(where: { $0.id == credentialId }) {
                    CredentialDetailView(credential: credential, viewModel: viewModel)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if subscriptionManager.checkCredentialLimit(currentCount: credentials.count) {
                            showAddCredential = true
                        } else {
                            subscriptionManager.triggerPaywall(reason: "You've hit your free limit of \(Constants.maxFreeCredentials) credentials. Upgrade to track all your credentials.")
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus")
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
}

struct CredentialRow: View {
    let credential: Credential

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: credential.credentialType.icon)
                .font(.title3)
                .foregroundStyle(Theme.statusColor(for: credential.status))
                .frame(width: 36, height: 36)
                .background(Theme.statusColor(for: credential.status).opacity(0.12))
                .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(credential.name.isEmpty ? credential.credentialType.rawValue : credential.name)
                    .font(.body.weight(.medium))

                HStack(spacing: 6) {
                    if let state = credential.state, !state.isEmpty {
                        Text(state)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let number = credential.credentialNumber, !number.isEmpty {
                        Text("#\(number)")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: credential.status.icon)
                        .font(.caption)
                    Text(credential.status.rawValue)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(Theme.statusColor(for: credential.status))

                if let date = credential.expirationDate {
                    Text(date.formatted(.dateTime.month(.abbreviated).year()))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(credential.name.isEmpty ? credential.credentialType.rawValue : credential.name), \(credential.status.rawValue)")
        .accessibilityHint("Double tap to view details")
    }
}
