import SwiftUI
import SwiftData
import VisionKit

struct DashboardView: View {
    let credentialVM: CredentialViewModel
    let cmeVM: CMEViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(sort: \Credential.expirationDate) private var credentials: [Credential]
    @Query(sort: \CMEActivity.dateCompleted, order: .reverse) private var activities: [CMEActivity]
    @Query private var cycles: [CMECycle]
    @State private var showAddCredential: Bool = false
    @State private var showAddCME: Bool = false
    @State private var showPaywall: Bool = false
    @State private var showScanner: Bool = false

    private var healthScore: HealthScore {
        credentialVM.healthScore(credentials)
    }

    private var upcomingRenewals: [Credential] {
        credentialVM.upcomingRenewals(credentials)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if !subscriptionManager.isPro {
                        upgradeBanner
                    }

                    healthScoreCard
                    quickActionsRow

                    if !upcomingRenewals.isEmpty {
                        alertsSection
                    }

                    if subscriptionManager.isPro, let cycle = cycles.first {
                        cmeProgressSection(cycle: cycle)
                    }

                    timelineSection
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showAddCredential) {
                AddCredentialView(viewModel: credentialVM)
            }
            .sheet(isPresented: $showAddCME) {
                AddCMEActivityView(viewModel: cmeVM)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    onDismiss: { showPaywall = false },
                    onSubscribe: { showPaywall = false }
                )
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
        }
    }

    // MARK: - Upgrade Banner

    private var upgradeBanner: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.credentialGold)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade to Pro")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Unlock reminders, CME tracking, and more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [Theme.credentialGold.opacity(0.12), Theme.credentialGold.opacity(0.04)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Theme.credentialGold.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Health Score Card

    private var healthScoreCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: healthScore.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(healthScoreColor)
                    .symbolEffect(.pulse, value: healthScore.title)

                VStack(alignment: .leading, spacing: 4) {
                    Text(healthScore.title)
                        .font(.title3.weight(.bold))
                    Text("\(credentials.count) credential\(credentials.count == 1 ? "" : "s") tracked")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if !credentials.isEmpty {
                HStack(spacing: 8) {
                    StatusPill(count: credentials.filter { $0.status == .current }.count, label: "Current", color: Theme.statusGreen)
                    StatusPill(count: credentials.filter { $0.status == .expiringSoon }.count, label: "Expiring", color: Theme.statusAmber)
                    StatusPill(count: credentials.filter { $0.status == .expired }.count, label: "Expired", color: Theme.statusRed)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Credential Health: \(healthScore.title). \(credentials.count) credentials tracked.")
        .accessibilityHint("Shows your overall credential compliance status")
    }

    private var healthScoreColor: Color {
        switch healthScore {
        case .good: return Theme.statusGreen
        case .attention: return Theme.statusAmber
        case .critical: return Theme.statusRed
        }
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            QuickActionButton(icon: "plus.circle.fill", label: "Add\nCredential", color: Theme.medicalBlue) {
                if subscriptionManager.checkCredentialLimit(currentCount: credentials.count) {
                    showAddCredential = true
                } else {
                    subscriptionManager.triggerPaywall(reason: "You've hit your free limit. Upgrade to track all your credentials.")
                    showPaywall = true
                }
            }
            QuickActionButton(icon: "book.circle.fill", label: "Log\nCME", color: Theme.credentialGold) {
                if subscriptionManager.isPro {
                    showAddCME = true
                } else {
                    subscriptionManager.triggerPaywall(reason: "Track CME hours and certificates with Pro.")
                    showPaywall = true
                }
            }
            QuickActionButton(icon: "camera.circle.fill", label: "Scan\nCertificate", color: Theme.statusGreen) {
                if subscriptionManager.isPro {
                    showScanner = true
                } else {
                    subscriptionManager.triggerPaywall(reason: "Scan and store certificates with Pro.")
                    showPaywall = true
                }
            }
        }
    }

    // MARK: - Alerts Section

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Needs Attention", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(Theme.statusAmber)

            ForEach(upcomingRenewals) { credential in
                CredentialAlertCard(credential: credential)
            }
        }
    }

    // MARK: - CME Progress

    private func cmeProgressSection(cycle: CMECycle) -> some View {
        let cycleActivities = cmeVM.activitiesForCycle(activities, cycle: cycle)
        let totalHours = cmeVM.totalHours(cycleActivities)
        let progress = min(totalHours / cycle.totalHoursRequired, 1.0)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("CME Progress", systemImage: "book.fill")
                    .font(.headline)
                Spacer()
                Text("\(totalHours, specifier: "%.1f") of \(cycle.totalHoursRequired, specifier: "%.0f") hrs")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 10)
                        Capsule()
                            .fill(progress >= 1 ? Theme.statusGreen : Theme.medicalBlue)
                            .frame(width: geo.size.width * progress, height: 10)
                    }
                }
                .frame(height: 10)
                .accessibilityLabel("CME Progress: \(Int(progress * 100)) percent complete")

                HStack {
                    Text("\(max(0, cycle.totalHoursRequired - totalHours), specifier: "%.1f") hrs remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(cycle.daysRemaining) days left in cycle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 14))
        }
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Upcoming Renewals", systemImage: "calendar")
                    .font(.headline)
                Spacer()
            }

            if credentials.isEmpty {
                ContentUnavailableView {
                    Label("No Credentials", systemImage: "doc.text")
                } description: {
                    Text("Add your first credential to start tracking.")
                }
                .frame(height: 200)
            } else {
                ForEach(credentials.sorted(by: { ($0.daysUntilExpiration ?? Int.max) < ($1.daysUntilExpiration ?? Int.max) })) { credential in
                    CredentialTimelineCard(credential: credential)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatusPill: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.subheadline.weight(.bold))
            Text(label)
                .font(.caption)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label)")
        .accessibilityAddTraits(.isStaticText)
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption2.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 14))
        }
        .accessibilityLabel(label.replacingOccurrences(of: "\n", with: " "))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to activate")
    }
}

struct CredentialAlertCard: View {
    let credential: Credential

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: credential.credentialType.icon)
                .font(.title3)
                .foregroundStyle(Theme.statusColor(for: credential.status))
                .frame(width: 36, height: 36)
                .background(Theme.statusColor(for: credential.status).opacity(0.12))
                .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(credential.name.isEmpty ? credential.credentialType.rawValue : credential.name)
                    .font(.subheadline.weight(.semibold))
                if let days = credential.daysUntilExpiration {
                    Text(days < 0 ? "Expired \(abs(days)) days ago" : "Expires in \(days) days")
                        .font(.caption)
                        .foregroundStyle(Theme.statusColor(for: credential.status))
                }
            }

            Spacer()

            Image(systemName: credential.status.icon)
                .foregroundStyle(Theme.statusColor(for: credential.status))
        }
        .padding(12)
        .background(Theme.statusColor(for: credential.status).opacity(0.06))
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(credential.name.isEmpty ? credential.credentialType.rawValue : credential.name), \(credential.status.rawValue), \(credential.daysUntilExpiration.map { $0 < 0 ? "expired \(abs($0)) days ago" : "expires in \($0) days" } ?? "no expiration date")")
    }
}

struct CredentialTimelineCard: View {
    let credential: Credential

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Circle()
                    .fill(Theme.statusColor(for: credential.status))
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 2)
            }
            .frame(height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(credential.name.isEmpty ? credential.credentialType.rawValue : credential.name)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    if let state = credential.state {
                        Text(state)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let date = credential.expirationDate {
                        Text(date.formatted(.dateTime.month(.abbreviated).day().year()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if let days = credential.daysUntilExpiration {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(max(0, days))")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(Theme.statusColor(for: credential.status))
                    Text("days")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(credential.name.isEmpty ? credential.credentialType.rawValue : credential.name), \(credential.daysUntilExpiration.map { "\(max(0, $0)) days remaining" } ?? "no expiration")")
    }
}
