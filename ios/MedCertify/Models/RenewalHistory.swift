import SwiftData
import Foundation

@Model
class RenewalHistory {
    var id: UUID
    var renewalDate: Date
    var previousExpiration: Date?
    var newExpiration: Date?
    var notes: String?
    var credential: Credential?

    init(
        renewalDate: Date = Date(),
        previousExpiration: Date? = nil,
        newExpiration: Date? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.renewalDate = renewalDate
        self.previousExpiration = previousExpiration
        self.newExpiration = newExpiration
        self.notes = notes
    }
}
