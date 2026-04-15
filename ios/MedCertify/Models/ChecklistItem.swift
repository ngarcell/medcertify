import SwiftData
import Foundation

@Model
class ChecklistItem {
    var id: UUID
    var title: String
    var completed: Bool
    var completedAt: Date?
    var credential: Credential?

    init(title: String, completed: Bool = false) {
        self.id = UUID()
        self.title = title
        self.completed = completed
    }
}
