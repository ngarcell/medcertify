import SwiftUI

struct AddCMECycleView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: CMEViewModel

    @State private var name: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()
    @State private var totalHours: String = "50"

    var body: some View {
        NavigationStack {
            Form {
                Section("Cycle Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cycle Name (e.g., 2025-2027 CME)").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $name)
                            .frame(minHeight: 36)
                            .scrollContentBackground(.hidden)
                    }
                }

                Section("Dates") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }

                Section("Requirements") {
                    HStack {
                        Text("Total Hours Required")
                        Spacer()
                        TextField("50", text: $totalHours)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .font(.body.monospacedDigit())
                    }
                }
            }
            .navigationTitle("CME Cycle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cycle = CMECycle(
                            name: name,
                            startDate: startDate,
                            endDate: endDate,
                            totalHoursRequired: Double(totalHours) ?? 50
                        )
                        viewModel.addCycle(cycle)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
