import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct DocumentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(sort: \CredentialDocument.uploadDate, order: .reverse) private var documents: [CredentialDocument]
    @State private var searchText: String = ""
    @State private var showPaywall: Bool = false
    @State private var showPhotosPicker: Bool = false
    @State private var showFilePicker: Bool = false
    @State private var showScanner: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showAddOptions: Bool = false

    private var filteredDocuments: [CredentialDocument] {
        if searchText.isEmpty { return documents }
        return documents.filter {
            $0.fileName.localizedStandardContains(searchText) ||
            $0.fileType.localizedStandardContains(searchText) ||
            $0.tags.contains(where: { $0.localizedStandardContains(searchText) })
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if subscriptionManager.isPro {
                    documentContent
                } else {
                    proOnlyOverlay
                }
            }
            .navigationTitle("Documents")
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
        }
    }

    // MARK: - Pro-Only Overlay

    private var proOnlyOverlay: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.credentialGold)

                Text("Document Vault")
                    .font(.title2.bold())

                Text("Store certificates, renewal confirmations,\nand important documents securely\non your device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                FeatureRow(icon: "camera.fill", text: "Scan documents with your camera")
                FeatureRow(icon: "photo.fill", text: "Import from photo library")
                FeatureRow(icon: "folder.fill", text: "Import PDFs and files")
                FeatureRow(icon: "shield.checkered", text: "Encrypted on-device storage")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                showPaywall = true
            } label: {
                Label("Unlock Document Vault", systemImage: "crown.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.medicalBlue)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Document Content

    private var documentContent: some View {
        List {
            if filteredDocuments.isEmpty {
                ContentUnavailableView {
                    Label("No Documents", systemImage: "folder")
                } description: {
                    Text("Tap + to add certificates, renewal confirmations, or other documents.")
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(filteredDocuments) { document in
                    DocumentRow(document: document)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                modelContext.delete(document)
                                try? modelContext.save()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search documents")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showScanner = true
                    } label: {
                        Label("Scan Document", systemImage: "doc.viewfinder")
                    }
                    Button {
                        showPhotosPicker = true
                    } label: {
                        Label("Photo Library", systemImage: "photo.fill")
                    }
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("Browse Files", systemImage: "folder.fill")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    // MARK: - Import Handlers

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

            let fileName = url.lastPathComponent
            let fileType = url.pathExtension.lowercased()

            let document = CredentialDocument(
                fileName: fileName,
                fileType: fileType,
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
}

struct DocumentRow: View {
    let document: CredentialDocument

    private var iconName: String {
        switch document.fileType.lowercased() {
        case "pdf": return "doc.fill"
        case "image", "jpg", "jpeg", "png", "heic": return "photo.fill"
        default: return "doc.text.fill"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(Theme.medicalBlue)
                .frame(width: 36, height: 36)
                .background(Theme.medicalBlue.opacity(0.1))
                .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(document.fileName)
                    .font(.body.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(document.fileType.uppercased())
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.medicalBlue.opacity(0.1))
                        .clipShape(Capsule())

                    if let size = document.fileData?.count {
                        Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Text(document.uploadDate.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(document.fileName), \(document.fileType) document")
    }
}
