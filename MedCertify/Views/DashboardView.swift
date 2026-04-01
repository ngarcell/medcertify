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

    private var compliancePercentage: Int {
        guard !credentials.isEmpty else { return 100 }
        let activeCount = credentials.filter { $0.status == .current }.count
        return Int((Double(activeCount) / Double(credentials.count) * 100).rounded())
    }

    private var sortedCredentials: [Credential] {
        credentials.sorted { ($0.daysUntilExpiration ?? Int.max) < ($1.daysUntilExpiration ?? Int.max) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                    topIdentityBar
                    welcomeSection

                    if !upcomingRenewals.isEmpty {
                        alertsSection
                    }

                    if subscriptionManager.isPro, let cycle = cycles.first {
                        cmeProgressSection(cycle: cycle)
                    }

                    credentialsSection
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            .background(MedCertifyHeroBackground())
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                addCredentialBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(.bar)
            }
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

    private var topIdentityBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 48, height: 48)
                        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)

                    Circle()
                        .stroke(Theme.primaryGradient, lineWidth: 2.5)
                        .frame(width: 48, height: 48)

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Theme.medicalBlue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Clinical Precision")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.headerText)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.warningGold)
                            .frame(width: 6, height: 6)
                        Text("ACTIVE STATUS")
                            .font(.caption.weight(.semibold))
                            .tracking(1.8)
                            .foregroundStyle(Theme.statusAmber)
                    }
                }
            }

            Spacer()

            Button {
            } label: {
                Image(systemName: "bell.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.mutedLabel)
                    .frame(width: 44, height: 44)
                    .background(Theme.surfaceCard, in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications")
        }
    }

    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Welcome, Dr. Aris")
                .font(.system(.largeTitle, design: .default, weight: .bold))
                .foregroundStyle(Theme.headerText)

            Text("Your clinical credentials are \(compliancePercentage)% compliant.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionEyebrow("Urgent Alerts")

            ForEach(upcomingRenewals.prefix(2)) { credential in
                CredentialAlertCard(credential: credential)
            }
        }
    }

    private func cmeProgressSection(cycle: CMECycle) -> some View {
        let cycleActivities = cmeVM.activitiesForCycle(activities, cycle: cycle)
        let totalHours = cmeVM.totalHours(cycleActivities)
        let progress = min(totalHours / max(cycle.totalHoursRequired, 1), 1.0)
        let categoryOneHours = cycleActivities
            .filter { $0.creditType.localizedStandardContains("Category 1") }
            .reduce(0) { $0 + $1.hours }
        let categoryTwoHours = cycleActivities
            .filter { $0.creditType.localizedStandardContains("Category 2") }
            .reduce(0) { $0 + $1.hours }

        return VStack(alignment: .leading, spacing: 18) {
            HStack {
                sectionEyebrow("CME Progress")
                Spacer()
                Button {
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.mutedLabel)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("More CME options")
            }

            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 14)
                        .frame(width: 176, height: 176)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Theme.medicalBlue, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 176, height: 176)

                    VStack(spacing: 2) {
                        Text("\(Int(totalHours.rounded()))")
                            .font(.system(.largeTitle, design: .default, weight: .bold))
                            .foregroundStyle(Theme.headerText)
                            .monospacedDigit()
                        Text("OF \(Int(cycle.totalHoursRequired.rounded())) CREDITS")
                            .font(.caption.weight(.bold))
                            .tracking(1.2)
                            .foregroundStyle(Theme.headerText.opacity(0.85))
                    }
                }
                .padding(.vertical, 8)
                Spacer()
            }

            Divider()

            HStack(spacing: 16) {
                CMEMetricBar(
                    title: "Category I",
                    valueText: "\(Int(categoryOneHours.rounded())) / 40",
                    progress: min(categoryOneHours / 40, 1)
                )
                CMEMetricBar(
                    title: "Category II",
                    valueText: "\(Int(categoryTwoHours.rounded())) / 10",
                    progress: min(categoryTwoHours / 10, 1),
                    tint: Theme.medicalBlueSecondary
                )
            }
        }
        .padding(22)
        .medCertifySecondaryCard()
    }

    private var credentialsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionEyebrow("My Credentials")
                Spacer()
                Button {
                } label: {
                    Text("View All")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.medicalBlue)
                }
                .buttonStyle(.plain)
            }

            if credentials.isEmpty {
                ContentUnavailableView {
                    Label("No Credentials", systemImage: "doc.text")
                } description: {
                    Text("Add your first credential to start tracking.")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .medCertifyCard()
            } else {
                ForEach(sortedCredentials.prefix(3)) { credential in
                    CredentialTimelineCard(credential: credential)
                }
            }
        }
    }

    private var addCredentialBar: some View {
        Button {
            if subscriptionManager.checkCredentialLimit(currentCount: credentials.count) {
                showAddCredential = true
            } else {
                subscriptionManager.triggerPaywall(reason: "You've hit your free limit. Upgrade to track all your credentials.")
                showPaywall = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                Text("Add New Credential")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Theme.primaryGradient, in: .rect(cornerRadius: 16))
            .shadow(color: Theme.medicalBlue.opacity(0.24), radius: 16, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Adds a new credential")
    }

    private func sectionEyebrow(_ title: String) -> some View {
        MedCertifySectionEyebrow(title: title)
    }
}

struct CMEMetricBar: View {
    let title: String
    let valueText: String
    let progress: Double
    var tint: Color = Theme.medicalBlue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.medium))
                .tracking(1.2)
                .foregroundStyle(Theme.mutedLabel)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(tint)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)

            Text(valueText)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Theme.headerText)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CredentialAlertCard: View {
    let credential: Credential

    private var statusColor: Color {
        Theme.statusColor(for: credential.status)
    }

    private var actionTitle: String {
        credential.status == .expired ? "Renew Now" : "Review Details"
    }

    private var statusTitle: String {
        switch credential.status {
        case .expired:
            return "EXPIRED"
        case .expiringSoon:
            return "EXPIRING"
        case .current:
            return "CURRENT"
        case .pending:
            return "PENDING"
        }
    }

    private var subtitle: String {
        guard let expirationDate = credential.expirationDate else {
            return "Expiration date needed to maintain clinical privileges."
        }

        if let days = credential.daysUntilExpiration, days < 0 {
            return "Expired on \(expirationDate.formatted(.dateTime.month(.abbreviated).day().year())). You must renew to maintain clinical privileges."
        }

        return "Expires in \(max(0, credential.daysUntilExpiration ?? 0)) days. Renewal window is now open in the portal."
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 10)
                .fill(statusColor)
                .frame(width: 4)
                .padding(.vertical, 18)

            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(statusColor.opacity(0.14))
                        .frame(width: 52, height: 52)
                    Image(systemName: credential.status == .expired ? "exclamationmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundStyle(statusColor)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Text(credential.name.isEmpty ? credential.credentialType.rawValue : credential.name)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Theme.headerText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(statusTitle)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(credential.status == .expired ? .white : Theme.headerText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(credential.status == .expired ? statusColor : Theme.warningGold, in: .capsule)
                    }

                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(Theme.headerText.opacity(0.9))

                    Button {
                    } label: {
                        HStack(spacing: 6) {
                            Text(actionTitle)
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Theme.medicalBlue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .medCertifyCard()
        .accessibilityElement(children: .combine)
    }
}

struct CredentialTimelineCard: View {
    let credential: Credential

    private var title: String {
        credential.name.isEmpty ? credential.credentialType.rawValue : credential.name
    }

    private var dateLabel: String {
        guard let expirationDate = credential.expirationDate else { return "No expiration" }
        return expirationDate.formatted(.dateTime.month(.abbreviated).year())
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.statusColor(for: credential.status).opacity(0.18))
                    .frame(width: 48, height: 48)

                Image(systemName: credential.credentialType.icon)
                    .font(.title3)
                    .foregroundStyle(Theme.medicalBlue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.headerText)

                Text(detailLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(trailingLabelTitle)
                    .font(.caption.weight(.medium))
                    .tracking(0.8)
                    .foregroundStyle(Theme.mutedLabel)
                Text(dateLabel)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.headerText)
                    .multilineTextAlignment(.trailing)
                if credential.status == .current {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.medicalBlue)
                }
            }
        }
        .padding(20)
        .medCertifyCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(detailLine), \(trailingLabelTitle) \(dateLabel)")
    }

    private var detailLine: String {
        let number = credential.credentialNumber?.isEmpty == false ? "ID: \(credential.credentialNumber ?? "")" : credential.issuingBody
        return "\(number) • \(credential.status.rawValue)"
    }

    private var trailingLabelTitle: String {
        switch credential.status {
        case .current:
            return "NEXT REVIEW"
        case .expiringSoon:
            return "EXPIRES"
        case .expired:
            return "EXPIRED"
        case .pending:
            return "STATUS"
        }
    }
}
