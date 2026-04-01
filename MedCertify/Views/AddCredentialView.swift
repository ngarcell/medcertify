import SwiftUI

struct AddCredentialView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager
    let viewModel: CredentialViewModel

    @State private var credentialType: CredentialType = .stateLicense
    @State private var name: String = ""
    @State private var issuingBody: String = ""
    @State private var state: String = ""
    @State private var credentialNumber: String = ""
    @State private var issueDate: Date = Date()
    @State private var hasIssueDate: Bool = false
    @State private var expirationDate: Date = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()
    @State private var renewalCycleMonths: Int = 24
    @State private var notes: String = ""
    @State private var showValidationError: Bool = false

    private var isFormValid: Bool {
        if credentialType == .other && name.isEmpty { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $credentialType) {
                        ForEach(CredentialType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Credential Type")
                } footer: {
                    Text("Select the type of credential you want to track.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $name)
                            .frame(minHeight: 36)
                            .scrollContentBackground(.hidden)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Issuing Body").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $issuingBody)
                            .frame(minHeight: 36)
                            .scrollContentBackground(.hidden)
                    }

                    if credentialType == .stateLicense || credentialType == .dea || credentialType == .controlledSubstance {
                        Picker("State", selection: $state) {
                            Text("Select State").tag("")
                            ForEach(Constants.usStates, id: \.self) { stateCode in
                                Text(Constants.stateNames[stateCode] ?? stateCode).tag(stateCode)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Credential Number").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $credentialNumber)
                            .frame(minHeight: 36)
                            .scrollContentBackground(.hidden)
                            .font(.body.monospaced())
                    }
                } header: {
                    Text("Details")
                }

                Section {
                    Toggle("Has Issue Date", isOn: $hasIssueDate)
                    if hasIssueDate {
                        DatePicker("Issue Date", selection: $issueDate, displayedComponents: .date)
                    }
                    DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                } header: {
                    Text("Dates")
                } footer: {
                    Text("We'll send renewal reminders based on your expiration date.")
                }

                Section("Renewal") {
                    Picker("Renewal Cycle", selection: $renewalCycleMonths) {
                        Text("1 Year").tag(12)
                        Text("2 Years").tag(24)
                        Text("3 Years").tag(36)
                        Text("5 Years").tag(60)
                        Text("10 Years").tag(120)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Add Credential")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isFormValid {
                            saveCredential()
                            dismiss()
                        } else {
                            showValidationError = true
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
            .alert("Missing Information", isPresented: $showValidationError) {
                Button("OK") {}
            } message: {
                Text("Please provide a name for custom credential types.")
            }
            .sensoryFeedback(.success, trigger: showValidationError)
        }
    }

    private func saveCredential() {
        let credential = Credential(
            type: credentialType.rawValue,
            name: name.isEmpty ? credentialType.rawValue : name,
            issuingBody: issuingBody,
            state: state.isEmpty ? nil : state,
            credentialNumber: credentialNumber.isEmpty ? nil : credentialNumber,
            issueDate: hasIssueDate ? issueDate : nil,
            expirationDate: expirationDate,
            renewalCycleMonths: renewalCycleMonths,
            notes: notes.isEmpty ? nil : notes
        )
        viewModel.addCredential(credential)

        // Schedule renewal reminders for Pro users
        if subscriptionManager.isPro {
            NotificationManager.shared.scheduleRenewalReminders(for: credential)
        }
    }
}
