import Foundation
import SwiftData

@Model
final class MedicationLog {
    var id: UUID
    var status: String // "taken", "skipped", "upcoming"
    var scheduledTime: Date
    var actionTime: Date?
    var medication: Medication?

    var logStatus: LogStatus {
        get { LogStatus(rawValue: status) ?? .upcoming }
        set { status = newValue.rawValue }
    }

    init(
        medication: Medication,
        scheduledTime: Date,
        status: LogStatus = .upcoming
    ) {
        self.id = UUID()
        self.medication = medication
        self.scheduledTime = scheduledTime
        self.status = status.rawValue
        self.actionTime = nil
    }
}

enum LogStatus: String, Codable {
    case taken
    case skipped
    case upcoming
}
