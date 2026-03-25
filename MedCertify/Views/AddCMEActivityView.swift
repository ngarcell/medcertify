import SwiftUI

struct AddCMEActivityView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: CMEViewModel

    @State private var activityTitle: String = ""
    @State private var provider: String = ""
    @State private var creditType: CMECreditType = .amaPRA1
    @State private var hours: String = ""
    @State private var dateCompleted: Date = Date()
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Activity Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Activity Title").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $activityTitle)
                            .frame(minHeight: 36)
                            .scrollContentBackground(.hidden)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Provider / Sponsor").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $provider)
                            .frame(minHeight: 36)
                            .scrollContentBackground(.hidden)
                    }
                }

                Section("Credit Information") {
                    Picker("Credit Type", selection: $creditType) {
                        ForEach(CMECreditType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack {
                        Text("Hours")
                        Spacer()
                        TextField("0.0", text: $hours)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .font(.body.monospacedDigit())
                    }

                    DatePicker("Date Completed", selection: $dateCompleted, displayedComponents: .date)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Log CME Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveActivity()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(activityTitle.isEmpty)
                }
            }
        }
    }

    private func saveActivity() {
        let activity = CMEActivity(
            activityTitle: activityTitle,
            provider: provider,
            creditType: creditType.rawValue,
            hours: Double(hours) ?? 0,
            dateCompleted: dateCompleted,
            notes: notes.isEmpty ? nil : notes
        )
        viewModel.addActivity(activity)
    }
}
