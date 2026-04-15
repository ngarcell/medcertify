import SwiftUI
import SwiftData

struct CMELogView: View {
    let viewModel: CMEViewModel
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(sort: \CMEActivity.dateCompleted, order: .reverse) private var activities: [CMEActivity]
    @Query private var cycles: [CMECycle]
    @Query private var profiles: [UserProfile]
    @State private var showAddActivity: Bool = false
    @State private var showAddCycle: Bool = false
    @State private var showPaywall: Bool = false
    @State private var selectedFilter: CMECreditType?

    private var profile: UserProfile? {
        profiles.first
    }

    private var educationLabel: String {
        profile?.educationTabTitle ?? "CME"
    }

    private var educationLongTitle: String {
        profile?.educationLongTitle ?? "Continuing Medical Education"
    }

    private var filteredActivities: [CMEActivity] {
        guard let filter = selectedFilter else { return activities }
        return activities.filter { $0.creditType == filter.rawValue }
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
            .navigationTitle(educationLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if subscriptionManager.isPro {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showAddActivity = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(Theme.inkAccent)
                        }
                    }
                }
            }
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

    private var lockedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(educationLongTitle)
                    .font(Theme.display(34, relativeTo: .largeTitle, prominent: true))
                    .foregroundStyle(Theme.headerText)

                Text("Keep hours, provider notes, and cycle pace in one place. Store proof in Vault so audits are less chaotic.")
                    .font(Theme.ui(16))
                    .foregroundStyle(Theme.mutedLabel)

                VStack(spacing: 12) {
                    lockedFeature(icon: "book.closed", title: "Clean activity logging", subtitle: "Record provider, date, type, and hours before they pile up.")
                    lockedFeature(icon: "chart.line.uptrend.xyaxis", title: "Cycle pace visibility", subtitle: "See whether you are on pace or need to close the gap.")
                    lockedFeature(icon: "folder", title: "Proof stays nearby", subtitle: "Keep documents in Vault instead of searching old inboxes.")
                }

                Button {
                    showPaywall = true
                } label: {
                    Text("Unlock \(educationLabel) tracking")
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
                Text(educationLongTitle)
                    .font(Theme.display(34, relativeTo: .largeTitle, prominent: true))
                    .foregroundStyle(Theme.headerText)

                Text("Record completed activities before they become year-end cleanup.")
                    .font(Theme.ui(16))
                    .foregroundStyle(Theme.mutedLabel)

                if let cycle = cycles.first {
                    cycleProgressSection(cycle: cycle)
                } else {
                    setupCycleCard
                }

                filterSection

                if filteredActivities.isEmpty {
                    emptyStateCard
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredActivities) { activity in
                            CMEActivityCard(activity: activity)
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
                    summarySection
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
    }

    private func cycleProgressSection(cycle: CMECycle) -> some View {
        let cycleActivities = viewModel.activitiesForCycle(activities, cycle: cycle)
        let totalHours = viewModel.totalHours(cycleActivities)
        let progress = min(totalHours / cycle.totalHoursRequired, 1.0)

        return VStack(alignment: .leading, spacing: 16) {
            Text(profile?.educationProgressTitle ?? "\(educationLabel) Progress")
                .font(Theme.ui(13, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Theme.copper)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(cycle.name.isEmpty ? "Current cycle" : cycle.name)
                        .font(Theme.display(25, relativeTo: .title2, prominent: true))
                        .foregroundStyle(Theme.headerText)
                    Text("Ends \(cycle.endDate.formatted(.dateTime.month(.wide).day().year()))")
                        .font(Theme.ui(14))
                        .foregroundStyle(Theme.mutedLabel)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(totalHours.rounded()))/\(Int(cycle.totalHoursRequired.rounded()))")
                        .font(Theme.display(28, relativeTo: .title2, prominent: true))
                        .foregroundStyle(Theme.headerText)
                    Text("hours")
                        .font(Theme.ui(12, weight: .medium))
                        .foregroundStyle(Theme.mutedLabel)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.surfaceMuted)
                        .frame(height: 12)
                    Capsule()
                        .fill(progress >= 1 ? Theme.statusGreen : Theme.inkAccent)
                        .frame(width: max(18, geo.size.width * progress), height: 12)
                }
            }
            .frame(height: 12)

            HStack {
                Text("\(cycle.daysRemaining) days remaining")
                    .font(Theme.ui(13))
                    .foregroundStyle(Theme.mutedLabel)
                Spacer()
                Text(progress >= 1 ? "On pace" : "Keep logging regularly")
                    .font(Theme.ui(13, weight: .semibold))
                    .foregroundStyle(progress >= 1 ? Theme.statusGreen : Theme.copper)
            }
        }
        .padding(Theme.cardPadding)
        .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.radiusLarge)
                .stroke(Theme.coolAccent.opacity(0.18), lineWidth: 1)
        }
    }

    private var setupCycleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set up your current cycle")
                .font(Theme.ui(17, weight: .semibold))
                .foregroundStyle(Theme.bodyText)
            Text("Add the date range and target hours so MedCertify can show whether you are on pace.")
                .font(Theme.ui(14))
                .foregroundStyle(Theme.mutedLabel)

            Button("Create cycle") {
                showAddCycle = true
            }
            .font(Theme.ui(15, weight: .semibold))
            .foregroundStyle(Theme.inkAccent)
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .stroke(Theme.subtleBorder, lineWidth: 1)
        }
    }

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                creditTypeChip(title: "All", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                ForEach(CMECreditType.allCases, id: \.self) { type in
                    creditTypeChip(title: type.rawValue, isSelected: selectedFilter == type) {
                        selectedFilter = type
                    }
                }
            }
        }
    }

    private func creditTypeChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
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
            Text("No \(educationLabel) activity in this view")
                .font(Theme.ui(17, weight: .semibold))
                .foregroundStyle(Theme.bodyText)
            Text("Log an activity as soon as it is complete so the record stays clean.")
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

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary by category")
                .font(Theme.ui(13, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Theme.copper)

            VStack(spacing: 10) {
                ForEach(CMECreditType.allCases, id: \.self) { type in
                    let hours = viewModel.totalHours(activities.filter { $0.creditType == type.rawValue })
                    if hours > 0 {
                        HStack {
                            Text(type.rawValue)
                                .font(Theme.ui(15, weight: .medium))
                                .foregroundStyle(Theme.bodyText)
                            Spacer()
                            Text("\(hours, specifier: "%.1f") hrs")
                                .font(Theme.ui(15, weight: .semibold))
                                .foregroundStyle(Theme.inkAccent)
                        }
                        .padding(16)
                        .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusMedium))
                        .overlay {
                            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                .stroke(Theme.subtleBorder, lineWidth: 1)
                        }
                    }
                }
            }
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

private struct CMEActivityCard: View {
    let activity: CMEActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.activityTitle)
                        .font(Theme.ui(17, weight: .semibold))
                        .foregroundStyle(Theme.bodyText)
                    Text(activity.provider.isEmpty ? "Provider not added" : activity.provider)
                        .font(Theme.ui(13))
                        .foregroundStyle(Theme.mutedLabel)
                }
                Spacer()
                Text("\(activity.hours, specifier: "%.1f") hrs")
                    .font(Theme.ui(15, weight: .semibold))
                    .foregroundStyle(Theme.inkAccent)
            }

            HStack(spacing: 10) {
                cmePill(title: activity.creditType)
                cmePill(title: activity.dateCompleted.formatted(.dateTime.month(.abbreviated).day().year()))
            }

            if let notes = activity.notes, !notes.isEmpty {
                Text(notes)
                    .font(Theme.ui(13))
                    .foregroundStyle(Theme.mutedLabel)
            }
        }
        .padding(Theme.cardPadding)
        .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Theme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.radiusLarge)
                .stroke(Theme.subtleBorder, lineWidth: 1)
        }
    }

    private func cmePill(title: String) -> some View {
        Text(title)
            .font(Theme.ui(12, weight: .semibold))
            .foregroundStyle(Theme.bodyText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.surfaceMuted.opacity(0.7), in: Capsule())
    }
}
