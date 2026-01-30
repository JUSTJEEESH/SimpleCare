import Foundation
import SwiftData

@Model
final class Medication {
    var id: UUID
    var name: String
    var dosage: String
    var notes: String
    var scheduleTimesData: Data?
    var isCritical: Bool
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \MedicationLog.medication)
    var logs: [MedicationLog]

    var scheduleTimes: [Date] {
        get {
            guard let data = scheduleTimesData else { return [] }
            return (try? JSONDecoder().decode([Date].self, from: data)) ?? []
        }
        set {
            scheduleTimesData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        name: String = "",
        dosage: String = "",
        notes: String = "",
        scheduleTimes: [Date] = [],
        isCritical: Bool = false,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.dosage = dosage
        self.notes = notes
        self.isCritical = isCritical
        self.isActive = isActive
        self.createdAt = Date()
        self.logs = []
        self.scheduleTimesData = try? JSONEncoder().encode(scheduleTimes)
    }
}
