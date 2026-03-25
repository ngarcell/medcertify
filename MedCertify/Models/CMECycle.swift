import SwiftData
import Foundation

@Model
class CMECycle {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var totalHoursRequired: Double
    var carryOverAllowed: Bool
    var maxCarryOverHours: Double
    var createdAt: Date

    init(
        name: String = "",
        startDate: Date = Date(),
        endDate: Date = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date(),
        totalHoursRequired: Double = 50,
        carryOverAllowed: Bool = false,
        maxCarryOverHours: Double = 0
    ) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.totalHoursRequired = totalHoursRequired
        self.carryOverAllowed = carryOverAllowed
        self.maxCarryOverHours = maxCarryOverHours
        self.createdAt = Date()
    }

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0)
    }

    var monthsRemaining: Int {
        max(0, Calendar.current.dateComponents([.month], from: Date(), to: endDate).month ?? 0)
    }
}
