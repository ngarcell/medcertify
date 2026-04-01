import SwiftUI
import SwiftData

struct CMELogView: View {
    let viewModel: CMEViewModel
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(sort: \CMEActivity.dateCompleted, order: .reverse) private var activities: [CMEActivity]
    @Query private var cycles: [CMECycle]
    @State private var showAddActivity: Bool = false
    @State private var showAddCycle: Bool = false
    @State private var showPaywall: Bool = false
    @State private var selectedFilter: CMECreditType?

    private var filteredActivities: [CMEActivity] {
        guard let filter = selectedFilter else { return activities }
        return activities.filter { $0.creditType == filter.rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if subscriptionManager.isPro {
                    cmeContent
                } else {
                    proOnlyOverlay
                }
            }
            .navigationTitle("CME Log")
            .sheet(isPresented: $showAddActivity) {
                AddCMEActivityView(viewModel: viewModel)
            }
            .sheet(isPresented: $showAddCycle) {
                AddCMECycleView(viewModel: viewModel)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    onDismiss: { showPaywall = false },
                    onSubscribe: { showPaywall = false }
                )
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

                Text("CME Tracking")
                    .font(.title2.bold())

                Text("Log CME activities, track cycle progress,\nand manage your continuing education —\nall in one place.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                FeatureRow(icon: "book.fill", text: "Log activities with credit type tracking")
                FeatureRow(icon: "chart.bar.fill", text: "Visual progress toward cycle goals")
                FeatureRow(icon: "bell.badge.fill", text: "Pace reminders if falling behind")
                FeatureRow(icon: "doc.text.fill", text: "Attach certificates to activities")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                showPaywall = true
            } label: {
                Label("Unlock CME Tracking", systemImage: "crown.fill")
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

    // MARK: - CME Content

    private var cmeContent: some View {
        List {
            if let cycle = cycles.first {
                cycleProgressSection(cycle: cycle)
            } else {
                Section {
                    Button {
                        showAddCycle = true
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundStyle(Theme.medicalBlue)
                            Text("Set Up CME Cycle")
                                .foregroundStyle(Theme.medicalBlue)
                        }
                    }
                }
            }

            filterSection

            Section("Activities") {
                if filteredActivities.isEmpty {
                    ContentUnavailableView {
                        Label("No Activities", systemImage: "book")
                    } description: {
                        Text("Tap + to log your first CME activity.")
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredActivities) { activity in
                        CMEActivityRow(activity: activity)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deleteActivity(activity)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }

            if !activities.isEmpty {
                hoursSummarySection
            }
        }
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddActivity = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    // MARK: - Cycle Progress

    private func cycleProgressSection(cycle: CMECycle) -> some View {
        let cycleActivities = viewModel.activitiesForCycle(activities, cycle: cycle)
        let totalHours = viewModel.totalHours(cycleActivities)
        let progress = min(totalHours / cycle.totalHoursRequired, 1.0)

        return Section {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cycle.name)
                            .font(.headline)
                        Text("Ending \(cycle.endDate.formatted(.dateTime.month(.wide).year()))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(totalHours, specifier: "%.1f")/\(cycle.totalHoursRequired, specifier: "%.0f")")
                            .font(.title3.weight(.bold).monospacedDigit())
                        Text("hours")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 12)
                        Capsule()
                            .fill(
                                progress >= 1.0 ? Theme.statusGreen :
                                progress >= 0.5 ? Theme.medicalBlue : Theme.statusAmber
                            )
                            .frame(width: geo.size.width * progress, height: 12)
                    }
                }
                .frame(height: 12)
                .accessibilityLabel("CME cycle progress: \(Int(progress * 100)) percent")

                HStack {
                    Text("\(cycle.daysRemaining) days remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if cycle.daysRemaining > 0 {
                        let monthsLeft = max(1, cycle.monthsRemaining)
                        let hoursPerMonth = max(0, cycle.totalHoursRequired - totalHours) / Double(monthsLeft)
                        Text("Pace: \(hoursPerMonth, specifier: "%.1f") hrs/month")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Filter

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                ForEach(CMECreditType.allCases, id: \.self) { type in
                    FilterChip(title: type.rawValue, isSelected: selectedFilter == type) {
                        selectedFilter = type
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    // MARK: - Hours Summary

    private var hoursSummarySection: some View {
        Section("Summary by Category") {
            ForEach(CMECreditType.allCases, id: \.self) { type in
                let hours = viewModel.totalHours(activities.filter { $0.creditType == type.rawValue })
                if hours > 0 {
                    HStack {
                        Text(type.rawValue)
                            .font(.subheadline)
                        Spacer()
                        Text("\(hours, specifier: "%.1f") hrs")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Theme.medicalBlue)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct CMEActivityRow: View {
    let activity: CMEActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(activity.activityTitle)
                    .font(.body.weight(.medium))
                Spacer()
                Text("\(activity.hours, specifier: "%.1f") hrs")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.medicalBlue)
            }
            HStack(spacing: 8) {
                Text(activity.creditType)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.medicalBlue.opacity(0.1))
                    .clipShape(Capsule())
                if !activity.provider.isEmpty {
                    Text(activity.provider)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(activity.dateCompleted.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activity.activityTitle), \(activity.hours, specifier: "%.1f") hours, \(activity.creditType)")
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.medicalBlue : Color(.secondarySystemGroupedBackground))
                .clipShape(Capsule())
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Theme.medicalBlue)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
    }
}
