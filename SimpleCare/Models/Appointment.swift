import Foundation
import SwiftData

@Model
final class Appointment {
    var id: UUID
    var title: String
    var doctorName: String
    var dateTime: Date
    var location: String
    var notes: String
    var prepReminder: Bool
    var prepReminderMinutes: Int
    var isCompleted: Bool
    var createdAt: Date

    init(
        title: String = "",
        doctorName: String = "",
        dateTime: Date = Date(),
        location: String = "",
        notes: String = "",
        prepReminder: Bool = false,
        prepReminderMinutes: Int = 60,
        isCompleted: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.doctorName = doctorName
        self.dateTime = dateTime
        self.location = location
        self.notes = notes
        self.prepReminder = prepReminder
        self.prepReminderMinutes = prepReminderMinutes
        self.isCompleted = isCompleted
        self.createdAt = Date()
    }
}
