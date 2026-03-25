import SwiftData
import Foundation

@Model
class CredentialDocument {
    var id: UUID
    var fileName: String
    var fileType: String
    @Attribute(.externalStorage) var fileData: Data?
    var linkedCredentialId: UUID?
    var tags: [String]
    var uploadDate: Date
    var notes: String?

    init(
        fileName: String = "",
        fileType: String = "image",
        fileData: Data? = nil,
        linkedCredentialId: UUID? = nil,
        tags: [String] = [],
        notes: String? = nil
    ) {
        self.id = UUID()
        self.fileName = fileName
        self.fileType = fileType
        self.fileData = fileData
        self.linkedCredentialId = linkedCredentialId
        self.tags = tags
        self.uploadDate = Date()
        self.notes = notes
    }
}
