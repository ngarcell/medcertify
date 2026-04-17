import SwiftUI
import SwiftData

struct CredentialDetailView: View {
    let credential: Credential
    let viewModel: CredentialViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var showEditSheet: Bool = false
    @State private var showRenewConfirmation: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                statusHeader
                detailsSection
                checklistSection
                renewalHistorySection
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(credential.name.isEmpty ? credential.credentialType.rawValue : credential.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit Credential", systemImage: "pencil")
                    }

                    Button {
                        showRenewConfirmation = true
                    } label: {
                        Label("Mark as Renewed", systemImage: "checkmark.seal.fill")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Credential", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditCredentialView(credential: credential)
        }
        .confirmationDialog("Mark as Renewed?", isPresented: $showRenewConfirmation) {
            Button("Confirm Renewal") {
                viewModel.renewCredential(credential)
                if subscriptionManager.isPro {
                    NotificationManager.shared.scheduleRenewalReminders(for: credential)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will update the expiration date by \(credential.renewalCycleMonths) months and reset the renewal checklist.")
        }
        .confirmationDialog("Delete Credential?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                NotificationManager.shared.cancelReminders(for: credential)
                viewModel.deleteCredential(credential)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All associated checklist items and renewal history will also be deleted.")
        }
    }

    // MARK: - Status Header

    private var statusHeader: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: credential.credentialType.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Theme.statusColor(for: credential.status))
                    .clipShape(.rect(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: credential.status.icon)
                            .font(.caption)
                        Text(credential.status.rawValue)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Theme.statusColor(for: credential.status))

                    if let days = credential.daysUntilExpiration {
                        Text(days < 0
                             ? "Expired \(abs(days)) days ago"
                             : days == 0
                             ? "Expires today"
                             : "\(days) days until expiration")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let days = credential.daysUntilExpiration, days >= 0 {
                    VStack(spacing: 2) {
                        Text("\(days)")
                            .font(.title.weight(.bold).monospacedDigit())
                            .foregroundStyle(Theme.statusColor(for: credential.status))
                        Text("days")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(credential.credentialType.rawValue), \(credential.status.rawValue), \(credential.daysUntilExpiration.map { "\($0) days until expiration" } ?? "no expiration date")")
        .accessibilityHint("Credential status summary")
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Details")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                if let state = credential.state, !state.isEmpty {
                    DetailRow(label: "State", value: state)
                    Divider().padding(.leading, 16)
                }

                if let number = credential.credentialNumber, !number.isEmpty {
                    DetailRow(label: "License #", value: number)
                    Divider().padding(.leading, 16)
                }

                if !credential.issuingBody.isEmpty {
                    DetailRow(label: "Issuing Body", value: credential.issuingBody)
                    Divider().padding(.leading, 16)
                }

                if let issueDate = credential.issueDate {
                    DetailRow(label: "Issue Date", value: issueDate.formatted(.dateTime.month(.wide).day().year()))
                    Divider().padding(.leading, 16)
                }

                if let expDate = credential.expirationDate {
                    DetailRow(label: "Expiration Date", value: expDate.formatted(.dateTime.month(.wide).day().year()))
                    Divider().padding(.leading, 16)
                }

                DetailRow(label: "Renewal Cycle", value: "\(credential.renewalCycleMonths) months")

                if let notes = credential.notes, !notes.isEmpty {
                    Divider().padding(.leading, 16)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(notes)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    // MARK: - Checklist

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Renewal Checklist")
                    .font(.headline)
                Spacer()
                let completed = credential.checklistItems.filter(\.completed).count
                if !credential.checklistItems.isEmpty {
                    Text("\(completed)/\(credential.checklistItems.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(completed == credential.checklistItems.count ? Theme.statusGreen : Theme.medicalBlue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            if credential.checklistItems.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checklist")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No checklist items")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(credential.checklistItems) { item in
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                item.completed.toggle()
                                item.completedAt = item.completed ? Date() : nil
                                try? modelContext.save()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(item.completed ? Theme.statusGreen : Color(.tertiaryLabel))
                                    .contentTransition(.symbolEffect(.replace))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.subheadline)
                                        .foregroundStyle(item.completed ? .secondary : .primary)
                                        .strikethrough(item.completed)

                                    if item.completed, let date = item.completedAt {
                                        Text("Completed \(date.formatted(.dateTime.month(.abbreviated).day()))")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .sensoryFeedback(.success, trigger: item.completed)
                        .accessibilityLabel("\(item.title), \(item.completed ? "completed" : "not completed")")
                        .accessibilityHint("Double tap to \(item.completed ? "unmark" : "mark") as completed")
                        .accessibilityAddTraits(.isButton)
                        if item.id != credential.checklistItems.last?.id {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    // MARK: - Renewal History

    private var renewalHistorySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Renewal History")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            if credential.renewalHistories.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No renewal history")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(credential.renewalHistories.sorted(by: { $0.renewalDate > $1.renewalDate })) { history in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Theme.statusGreen)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Renewed \(history.renewalDate.formatted(.dateTime.month(.wide).day().year()))")
                                    .font(.subheadline)
                                if let newExp = history.newExpiration {
                                    Text("New expiration: \(newExp.formatted(.dateTime.month(.abbreviated).year()))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let notes = history.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                        if history.id != credential.renewalHistories.last?.id {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Edit Credential View

struct EditCredentialView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var credential: Credential

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Credential Type", selection: $credential.type) {
                        ForEach(CredentialType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type.rawValue)
                        }
                    }
                }

                Section("Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $credential.name)
                            .frame(minHeight: 36)
                            .scrollContentBackground(.hidden)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Issuing Body").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $credential.issuingBody)
                            .frame(minHeight: 36)
                            .scrollContentBackground(.hidden)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("License Number").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: Binding(
                            get: { credential.credentialNumber ?? "" },
                            set: { credential.credentialNumber = $0.isEmpty ? nil : $0 }
                        ))
                        .frame(minHeight: 36)
                        .scrollContentBackground(.hidden)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("State").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: Binding(
                            get: { credential.state ?? "" },
                            set: { credential.state = $0.isEmpty ? nil : $0 }
                        ))
                        .frame(minHeight: 36)
                        .scrollContentBackground(.hidden)
                    }
                }

                Section("Dates") {
                    DatePicker("Issue Date", selection: Binding(
                        get: { credential.issueDate ?? Date() },
                        set: { credential.issueDate = $0 }
                    ), displayedComponents: .date)

                    DatePicker("Expiration Date", selection: Binding(
                        get: { credential.expirationDate ?? Date() },
                        set: { credential.expirationDate = $0 }
                    ), displayedComponents: .date)

                    Stepper("Renewal Cycle: \(credential.renewalCycleMonths) months",
                            value: $credential.renewalCycleMonths, in: 1...120)
                }

                Section("Notes") {
                    TextEditor(text: Binding(
                        get: { credential.notes ?? "" },
                        set: { credential.notes = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 80)
                }
            }
            .navigationTitle("Edit Credential")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        try? modelContext.save()
                        NotificationManager.shared.scheduleRenewalReminders(for: credential)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
