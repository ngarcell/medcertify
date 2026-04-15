import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct DocumentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(sort: \CredentialDocument.uploadDate, order: .reverse) private var documents: [CredentialDocument]
    @Query(sort: \Credential.expirationDate) private var credentials: [Credential]

    @State private var searchText: String = ""
    @State private var showPaywall: Bool = false
    @State private var showPhotosPicker: Bool = false
    @State private var showFilePicker: Bool = false
    @State private var showScanner: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedCredentialScope: UUID?
    @State private var showingUnlinkedOnly: Bool = false

    private var filteredDocuments: [CredentialDocument] {
        documents.filter { document in
            let linkedCredential = credentials.first(where: { $0.id == document.linkedCredentialId })
            let matchesSearch = searchText.isEmpty
                || document.fileName.localizedStandardContains(searchText)
                || document.fileType.localizedStandardContains(searchText)
                || document.tags.contains(where: { $0.localizedStandardContains(searchText) })
                || (linkedCredential?.displayName.localizedStandardContains(searchText) ?? false)

            let matchesScope: Bool
            if showingUnlinkedOnly {
                matchesScope = document.linkedCredentialId == nil
            } else if let selectedCredentialScope {
                matchesScope = document.linkedCredentialId == selectedCredentialScope
            } else {
                matchesScope = true
            }

            return matchesSearch && matchesScope
        }
    }

    private var selectedScopeLabel: String {
        if showingUnlinkedOnly {
            return "Unlinked"
        }
        if let selectedCredentialScope, let credential = credentials.first(where: { $0.id == selectedCredentialScope }) {
            return credential.displayName
        }
        return "All"
    }

    private var linkedDocumentCount: Int {
        documents.filter { $0.linkedCredentialId != nil }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if subscriptionManager.isPro {
                    activeContent
                } else {
                    lockedContent
                }
            }
            .background(Theme.canvasGradient)
            .navigationTitle("Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showScanner = true
                        } label: {
                            Label("Scan proof", systemImage: "doc.viewfinder")
                        }
                        Button {
                            showPhotosPicker = true
                        } label: {
                            Label("Import photo", systemImage: "photo")
                        }
                        Button {
                            showFilePicker = true
                        } label: {
                            Label("Browse files", systemImage: "folder")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(subscriptionManager.isPro ? Theme.inkAccent : Theme.mutedLabel)
                    }
                    .disabled(!subscriptionManager.isPro)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    onDismiss: { showPaywall = false },
                    onSubscribe: { showPaywall = false }
                )
            }
            .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhotoItem, matching: .images)
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf, .image, .png, .jpeg],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
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
            .onChange(of: selectedPhotoItem) { _, newValue in
                if let item = newValue {
                    Task { await importPhoto(item) }
                }
            }
            .searchable(text: $searchText, prompt: "Search vault")
        }
    }

    private var lockedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Vault")
                    .font(Theme.display(34, relativeTo: .largeTitle, prominent: true))
                    .foregroundStyle(Theme.headerText)

                Text("Keep scanned renewals, certificates, and confirmations in one place you can reach quickly when a board or employer asks for proof.")
                    .font(Theme.ui(16))
                    .foregroundStyle(Theme.mutedLabel)

                VStack(spacing: 12) {
                    lockedFeature(icon: "doc.viewfinder", title: "Scan on the spot", subtitle: "Capture a renewal letter or certificate the moment you receive it.")
                    lockedFeature(icon: "link", title: "Link proof to the right credential", subtitle: "Make renewal paperwork easier to retrieve later.")
                    lockedFeature(icon: "lock.shield", title: "Keep it local", subtitle: "Your vault stays on device and under your control.")
                }

                Button {
                    showPaywall = true
                } label: {
                    Text("Unlock Vault")
                        .font(Theme.ui(17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Theme.primaryGradient, in: RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.screenPadding)
        }
    }

    private var activeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Vault")
                    .font(Theme.display(34, relativeTo: .largeTitle, prominent: true))
                    .foregroundStyle(Theme.headerText)

                Text("Store proof once, then link it to the credential that needs it.")
                    .font(Theme.ui(16))
                    .foregroundStyle(Theme.mutedLabel)

                statsSection
                scopeSection

                if filteredDocuments.isEmpty {
                    emptyStateCard
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredDocuments) { document in
                            VaultDocumentCard(
                                document: document,
                                linkedCredential: credentials.first(where: { $0.id == document.linkedCredentialId }),
                                credentials: credentials,
                                onLink: { credentialID in
                                    document.linkedCredentialId = credentialID
                                    try? modelContext.save()
                                },
                                onDelete: {
                                    modelContext.delete(document)
                                    try? modelContext.save()
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            vaultMetric(title: "Stored", value: "\(documents.count)", caption: documents.isEmpty ? "No proof yet" : "Items in vault")
            vaultMetric(title: "Linked", value: "\(linkedDocumentCount)", caption: documents.isEmpty ? "Start by importing proof" : "Connected to credentials")
        }
    }

    private func vaultMetric(title: String, value: String, caption: String) -> some View {
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

    private var scopeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                scopeChip(title: "All", isSelected: !showingUnlinkedOnly && selectedCredentialScope == nil) {
                    showingUnlinkedOnly = false
                    selectedCredentialScope = nil
                }
                scopeChip(title: "Unlinked", isSelected: showingUnlinkedOnly) {
                    showingUnlinkedOnly = true
                    selectedCredentialScope = nil
                }

                Menu {
                    ForEach(credentials) { credential in
                        Button(credential.displayName) {
                            showingUnlinkedOnly = false
                            selectedCredentialScope = credential.id
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(selectedCredentialScope == nil ? "By credential" : selectedScopeLabel)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(Theme.ui(13, weight: .semibold))
                    .foregroundStyle(selectedCredentialScope != nil ? .white : Theme.bodyText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(selectedCredentialScope != nil ? Theme.primaryGradient : LinearGradient(colors: [Theme.surfaceCard], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(selectedCredentialScope != nil ? Color.clear : Theme.subtleBorder, lineWidth: 1)
                    }
                }
            }

            Text("Viewing: \(selectedScopeLabel)")
                .font(Theme.ui(13))
                .foregroundStyle(Theme.mutedLabel)
        }
    }

    private func scopeChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.ui(13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Theme.bodyText)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? Theme.primaryGradient : LinearGradient(colors: [Theme.surfaceCard], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                .overlay {
                    Capsule().stroke(isSelected ? Color.clear : Theme.subtleBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(documents.isEmpty ? "Your vault is empty." : "No documents match this view.")
                .font(Theme.ui(17, weight: .semibold))
                .foregroundStyle(Theme.bodyText)
            Text(documents.isEmpty ? "Scan a certificate or import a file so proof is ready when a deadline gets close." : "Try another scope or search term.")
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
    }

    private func importPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }

        let document = CredentialDocument(
            fileName: "Photo_\(Date().formatted(.dateTime.year().month().day().hour().minute()))",
            fileType: "image",
            fileData: data,
            tags: ["imported"],
            notes: ""
        )

        await MainActor.run {
            modelContext.insert(document)
            try? modelContext.save()
            selectedPhotoItem = nil
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let data = try? Data(contentsOf: url) else { return }

            let document = CredentialDocument(
                fileName: url.lastPathComponent,
                fileType: url.pathExtension.lowercased(),
                fileData: data,
                tags: ["imported"],
                notes: ""
            )

            modelContext.insert(document)
            try? modelContext.save()

        case .failure(let error):
            print("File import failed: \(error)")
        }
    }

    private func lockedFeature(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.inkAccent.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: icon)
                        .foregroundStyle(Theme.inkAccent)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.ui(16, weight: .semibold))
                    .foregroundStyle(Theme.bodyText)
                Text(subtitle)
                    .font(Theme.ui(13))
                    .foregroundStyle(Theme.mutedLabel)
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
}

private struct VaultDocumentCard: View {
    let document: CredentialDocument
    let linkedCredential: Credential?
    let credentials: [Credential]
    let onLink: (UUID?) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.inkAccent.opacity(0.1))
                    .frame(width: 48, height: 48)
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
                        .foregroundStyle(linkedCredential == nil ? Theme.copper : Theme.mutedLabel)

                    Text(document.uploadDate.formatted(.dateTime.month(.wide).day().year()))
                        .font(Theme.ui(12))
                        .foregroundStyle(Theme.mutedLabel)
                }

                Spacer()

                Menu {
                    if !credentials.isEmpty {
                        Menu("Link to credential") {
                            ForEach(credentials) { credential in
                                Button(credential.displayName) {
                                    onLink(credential.id)
                                }
                            }
                        }
                    }

                    if linkedCredential != nil {
                        Button("Remove link") {
                            onLink(nil)
                        }
                    }

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(Theme.mutedLabel)
                }
            }

            HStack(spacing: 10) {
                vaultPill(title: document.fileBadgeText)
                if let size = document.fileData?.count {
                    vaultPill(title: ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                }
                vaultPill(title: linkedCredential == nil ? "Needs link" : "Linked")
            }
        }
        .padding(Theme.cardPadding)
        .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.radiusLarge)
                .stroke(Theme.subtleBorder, lineWidth: 1)
        }
    }

    private func vaultPill(title: String) -> some View {
        Text(title)
            .font(Theme.ui(12, weight: .semibold))
            .foregroundStyle(Theme.bodyText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.surfaceMuted.opacity(0.7), in: Capsule())
    }
}
