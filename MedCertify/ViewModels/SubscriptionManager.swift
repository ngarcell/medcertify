import SwiftUI
import StoreKit

@MainActor @Observable
class SubscriptionManager {
    /// Set to `true` after Paid Apps Agreement, banking/tax, and subscription products are live in App Store Connect.
    static let subscriptionsOfferedInApp = false

    // MARK: - Product Identifiers
    /// Primary product IDs expected in App Store Connect.
    static let annualProductID = "com.medcertify.pro.annual"
    static let monthlyProductID = "com.medcertify.pro.monthly"

    /// Legacy / fallback IDs accepted during migrations.
    static let legacyAnnualProductID = "com.socialreporthq.credvault.pro.annual"
    static let legacyMonthlyProductID = "com.socialreporthq.credvault.pro.monthly"

    // MARK: - State
    var isPro: Bool = false
    var showPaywall: Bool = false
    var paywallTrigger: String = ""
    var products: [Product] = []
    var purchaseInProgress: Bool = false
    var purchaseError: String?
    var transactionListenerTask: Task<Void, Error>?

    private static var annualProductIDs: [String] {
        var ids = [annualProductID, legacyAnnualProductID]
        if let bundleID = Bundle.main.bundleIdentifier {
            ids.append("\(bundleID).pro.annual")
        }
        return dedupe(ids)
    }

    private static var monthlyProductIDs: [String] {
        var ids = [monthlyProductID, legacyMonthlyProductID]
        if let bundleID = Bundle.main.bundleIdentifier {
            ids.append("\(bundleID).pro.monthly")
        }
        return dedupe(ids)
    }

    private static var allProductIDs: [String] {
        dedupe(annualProductIDs + monthlyProductIDs)
    }

    private static func dedupe(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        return ids.filter { seen.insert($0).inserted }
    }

    // MARK: - Persisted State
    private let isProKey = "medcertify_isPro"
    private let trialStartKey = "medcertify_trialStart"

    // MARK: - Testing / Sandbox Detection
    /// Detects StoreKit sandbox or Xcode environment for Apple reviewer testing
    static var isSandboxEnvironment: Bool {
        #if DEBUG
        return true
        #else
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
        return receiptURL.lastPathComponent == "sandboxReceipt"
        #endif
    }

    init() {
        if !Self.subscriptionsOfferedInApp {
            isPro = true
            UserDefaults.standard.set(true, forKey: isProKey)
        } else if Self.isSandboxEnvironment {
            isPro = true
            UserDefaults.standard.set(true, forKey: isProKey)
        } else {
            isPro = UserDefaults.standard.bool(forKey: isProKey)
        }
    }

    // MARK: - Product Loading

    func loadProducts() async {
        guard Self.subscriptionsOfferedInApp else {
            products = []
            purchaseError = nil
            return
        }
        // Clear any previous error when reloading product information.
        purchaseError = nil
        do {
            let storeProducts = try await Product.products(for: Self.allProductIDs)
            products = storeProducts.sorted { $0.price > $1.price }

            // If one (or both) products are missing, treat it as a recoverable configuration issue.
            let loadedIDs = Set(storeProducts.map { $0.id })
            var missing: [String] = []
            if !Self.annualProductIDs.contains(where: loadedIDs.contains) { missing.append("annual") }
            if !Self.monthlyProductIDs.contains(where: loadedIDs.contains) { missing.append("monthly") }
            if !missing.isEmpty {
                purchaseError = "Subscription options are not available right now. Please try again."
                print("Missing expected subscription products (\(missing)). Loaded IDs: \(loadedIDs)")
            }
        } catch {
            purchaseError = "Unable to load subscription options. Please try again."
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        guard Self.subscriptionsOfferedInApp else { return }
        purchaseInProgress = true
        purchaseError = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus()
                await transaction.finish()
            case .userCancelled:
                // Intentionally no error — user dismissed the payment sheet.
                purchaseError = nil
            case .pending:
                purchaseError = "Purchase is pending approval. You will be notified once it completes."
            @unknown default:
                purchaseError = "Purchase result unavailable. Please try again."
            }
        } catch {
            purchaseError = Self.friendlyPurchaseMessage(for: error)
            if purchaseError != nil {
                print("Purchase failed: \(error)")
            }
        }

        purchaseInProgress = false
    }

    func purchaseAnnual() async {
        guard Self.subscriptionsOfferedInApp else { return }
        var product = annualProduct
        if product == nil {
            await loadProducts()
            product = annualProduct
        }
        guard let product else {
            purchaseError = "Annual subscription is unavailable right now. Check your connection or try again later."
            return
        }
        await purchase(product)
    }

    func purchaseMonthly() async {
        guard Self.subscriptionsOfferedInApp else { return }
        var product = monthlyProduct
        if product == nil {
            await loadProducts()
            product = monthlyProduct
        }
        guard let product else {
            purchaseError = "Monthly subscription is unavailable right now. Check your connection or try again later."
            return
        }
        await purchase(product)
    }

    /// Maps StoreKit errors to short user-facing copy. Returns `nil` when the user cancelled (no alert).
    private static func friendlyPurchaseMessage(for error: Error) -> String? {
        if let pe = error as? Product.PurchaseError {
            switch pe {
            case .productUnavailable:
                return "This subscription isn’t available right now. Please try again later."
            case .purchaseNotAllowed:
                return "Purchases aren’t allowed on this device. Check Screen Time or parental controls."
            case .ineligibleForOffer:
                return "This offer isn’t available for your account."
            case .invalidOfferIdentifier, .invalidOfferPrice, .invalidOfferSignature, .missingOfferParameters, .invalidQuantity:
                return "Purchase could not be completed. Please try again."
            @unknown default:
                return "Purchase could not be completed. Please try again."
            }
        }
        if let sk = error as? StoreKitError {
            switch sk {
            case .userCancelled:
                return nil
            case .networkError:
                return "Unable to reach the App Store. Check your connection and try again."
            case .systemError:
                return "Something went wrong with the App Store. Please try again in a moment."
            case .notAvailableInStorefront, .notEntitled, .unknown, .unsupported:
                return "Purchase could not be completed. Please try again."
            @unknown default:
                return "Purchase could not be completed. Please try again."
            }
        }
        return "Purchase could not be completed. Please try again."
    }

    // MARK: - Restore

    func restorePurchases() async {
        guard Self.subscriptionsOfferedInApp else { return }
        purchaseInProgress = true
        purchaseError = nil

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            purchaseError = "Restore failed. Please try again."
        }

        purchaseInProgress = false
    }

    // MARK: - Subscription Status

    func updateSubscriptionStatus() async {
        if !Self.subscriptionsOfferedInApp {
            isPro = true
            UserDefaults.standard.set(true, forKey: isProKey)
            return
        }

        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if Self.allProductIDs.contains(transaction.productID) {
                    if transaction.revocationDate == nil {
                        hasActiveSubscription = true
                    }
                }
            }
        }

        // In sandbox, always keep Pro unlocked for Apple reviewer testing
        if Self.isSandboxEnvironment {
            hasActiveSubscription = true
        }

        isPro = hasActiveSubscription
        UserDefaults.standard.set(hasActiveSubscription, forKey: isProKey)
    }

    // MARK: - Transaction Listener

    func listenForTransactions() {
        guard Self.subscriptionsOfferedInApp else { return }
        transactionListenerTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self?.updateSubscriptionStatus()
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Free Tier Checks

    var canAddCredential: Bool {
        isPro
    }

    func checkCredentialLimit(currentCount: Int) -> Bool {
        if isPro { return true }
        return currentCount < Constants.maxFreeCredentials
    }

    func triggerPaywall(reason: String) {
        guard Self.subscriptionsOfferedInApp else { return }
        paywallTrigger = reason
        showPaywall = true
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    var annualProduct: Product? {
        products.first { Self.annualProductIDs.contains($0.id) }
    }

    var monthlyProduct: Product? {
        products.first { Self.monthlyProductIDs.contains($0.id) }
    }
}

enum StoreError: Error {
    case failedVerification
}

// MARK: - Notification Manager

import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    // MARK: - Permission

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    // MARK: - Schedule Renewal Reminders

    func scheduleRenewalReminders(for credential: Credential) {
        guard let expirationDate = credential.expirationDate else { return }

        cancelReminders(for: credential)

        for daysBefore in credential.reminderDays {
            guard let triggerDate = Calendar.current.date(
                byAdding: .day, value: -daysBefore, to: expirationDate
            ) else { continue }

            guard triggerDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            let credName = credential.name.isEmpty ? credential.credentialType.rawValue : credential.name

            if daysBefore <= 7 {
                content.title = "⚠️ Urgent: \(credName)"
                content.body = "Expires in \(daysBefore) day\(daysBefore == 1 ? "" : "s"). Take action now."
                content.sound = .default
            } else if daysBefore <= 30 {
                content.title = "\(credName) Renewal"
                content.body = "Expires in \(daysBefore) days. Check your renewal checklist."
                content.sound = .default
            } else {
                content.title = "\(credName) Renewal Upcoming"
                content.body = "Expires in \(daysBefore) days. Start planning your renewal."
                content.sound = .default
            }

            content.categoryIdentifier = "CREDENTIAL_RENEWAL"
            content.userInfo = ["credentialId": credential.id.uuidString]

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: triggerDate) ?? triggerDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let identifier = notificationId(for: credential, daysBefore: daysBefore)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("Failed to schedule notification: \(error)")
                }
            }
        }
    }

    // MARK: - Cancel Reminders

    func cancelReminders(for credential: Credential) {
        let identifiers = credential.reminderDays.map { daysBefore in
            notificationId(for: credential, daysBefore: daysBefore)
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Refresh All

    func refreshAllReminders(for credentials: [Credential]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        for credential in credentials {
            scheduleRenewalReminders(for: credential)
        }
    }

    // MARK: - Expired Credential Alert

    func scheduleExpiredAlert(for credential: Credential) {
        guard let expirationDate = credential.expirationDate,
              expirationDate < Date() else { return }

        let content = UNMutableNotificationContent()
        let credName = credential.name.isEmpty ? credential.credentialType.rawValue : credential.name
        let daysSince = abs(Calendar.current.dateComponents([.day], from: expirationDate, to: Date()).day ?? 0)

        content.title = "⚠️ EXPIRED: \(credName)"
        content.body = "Your \(credName) expired \(daysSince) days ago. Take action immediately."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = "CREDENTIAL_EXPIRED"
        content.userInfo = ["credentialId": credential.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "expired_\(credential.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - CME Pace Reminder

    func scheduleCMEPaceReminder(hoursNeeded: Double, deadline: Date) {
        let content = UNMutableNotificationContent()
        let monthsLeft = max(1, Calendar.current.dateComponents([.month], from: Date(), to: deadline).month ?? 1)
        let pacePerMonth = hoursNeeded / Double(monthsLeft)

        content.title = "📚 CME Progress Check"
        content.body = String(format: "You need %.1f more CME hours by %@. That's %.1f hrs/month.", hoursNeeded, deadline.formatted(.dateTime.month(.wide).year()), pacePerMonth)
        content.sound = .default
        content.categoryIdentifier = "CME_PACE"

        var components = Calendar.current.dateComponents([.year, .month], from: Date())
        components.day = 1
        components.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: "cme_pace_monthly", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Trial ReminderS

    func scheduleTrialEndReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Free Trial Ending Tomorrow"
        content.body = "Your MedCertify Pro trial ends tomorrow. Your credentials are safe — keep full access by subscribing."
        content.sound = .default
        content.categoryIdentifier = "TRIAL_END"

        guard let triggerDate = Calendar.current.date(byAdding: .day, value: 6, to: Date()) else { return }
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour],
            from: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: triggerDate) ?? triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "trial_end_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Helpers

    private func notificationId(for credential: Credential, daysBefore: Int) -> String {
        "renewal_\(credential.id.uuidString)_\(daysBefore)"
    }
}
