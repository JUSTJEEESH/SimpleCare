import UserNotifications
import UIKit

@MainActor
final class NotificationService {
    nonisolated(unsafe) static let shared = NotificationService()

    private init() {}

    // MARK: - Permission

    func requestPermission(completion: @escaping @Sendable (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    // MARK: - Medication Reminders

    func scheduleMedicationReminders(for medication: Medication) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current

        for (index, time) in medication.scheduleTimes.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Time for your medication"
            content.body = "It's time to take your \(medication.name)."
            if !medication.dosage.isEmpty {
                content.body += " (\(medication.dosage))"
            }
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            content.categoryIdentifier = "MEDICATION_REMINDER"

            // Create daily repeating trigger
            var dateComponents = DateComponents()
            dateComponents.hour = calendar.component(.hour, from: time)
            dateComponents.minute = calendar.component(.minute, from: time)

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )

            let identifier = "med-\(medication.id.uuidString)-\(index)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            center.add(request)

            // Follow-up reminder 45 minutes later for missed doses
            let followUpContent = UNMutableNotificationContent()
            followUpContent.title = "Friendly reminder"
            followUpContent.body = "You haven't marked \(medication.name) as taken yet."
            followUpContent.sound = .default
            followUpContent.categoryIdentifier = "MEDICATION_REMINDER"

            let originalHour = dateComponents.hour ?? 0
            let originalMinute = dateComponents.minute ?? 0
            let totalMinutes = originalHour * 60 + originalMinute + 45

            var followUpComponents = DateComponents()
            followUpComponents.hour = totalMinutes / 60
            followUpComponents.minute = totalMinutes % 60

            let followUpTrigger = UNCalendarNotificationTrigger(
                dateMatching: followUpComponents,
                repeats: true
            )

            let followUpRequest = UNNotificationRequest(
                identifier: "med-followup-\(medication.id.uuidString)-\(index)",
                content: followUpContent,
                trigger: followUpTrigger
            )

            center.add(followUpRequest)
        }

        // Register action categories
        registerCategories()
    }

    func cancelReminders(for medication: Medication) {
        let center = UNUserNotificationCenter.current()
        let identifiers = medication.scheduleTimes.indices.flatMap { index in
            [
                "med-\(medication.id.uuidString)-\(index)",
                "med-followup-\(medication.id.uuidString)-\(index)"
            ]
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Appointment Reminders

    func scheduleAppointmentReminder(for appointment: Appointment) {
        let center = UNUserNotificationCenter.current()

        // Main reminder
        let content = UNMutableNotificationContent()
        let title = appointment.title.isEmpty ? appointment.doctorName : appointment.title
        content.title = "Upcoming Appointment"
        content.body = "\(title) today."
        if !appointment.location.isEmpty {
            content.body += " at \(appointment.location)"
        }
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: appointment.dateTime.addingTimeInterval(-3600) // 1 hour before
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(
            identifier: "apt-\(appointment.id.uuidString)",
            content: content,
            trigger: trigger
        )
        center.add(request)

        // Prep reminder if enabled
        if appointment.prepReminder {
            let prepContent = UNMutableNotificationContent()
            prepContent.title = "Appointment Reminder"
            prepContent.body = "Don't forget: \(title) is coming up."
            if !appointment.notes.isEmpty {
                prepContent.body += " Note: \(appointment.notes)"
            }
            prepContent.sound = .default

            let prepDate = appointment.dateTime.addingTimeInterval(
                -Double(appointment.prepReminderMinutes * 60)
            )
            let prepTrigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: prepDate
                ),
                repeats: false
            )

            let prepRequest = UNNotificationRequest(
                identifier: "apt-prep-\(appointment.id.uuidString)",
                content: prepContent,
                trigger: prepTrigger
            )
            center.add(prepRequest)
        }
    }

    func cancelAppointmentReminder(for appointment: Appointment) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            "apt-\(appointment.id.uuidString)",
            "apt-prep-\(appointment.id.uuidString)"
        ])
    }

    // MARK: - Action Categories

    private func registerCategories() {
        let takenAction = UNNotificationAction(
            identifier: "TAKEN",
            title: "Taken",
            options: []
        )
        let skipAction = UNNotificationAction(
            identifier: "SKIP",
            title: "Skip",
            options: []
        )
        let remindAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind Me Later",
            options: []
        )

        let medicationCategory = UNNotificationCategory(
            identifier: "MEDICATION_REMINDER",
            actions: [takenAction, skipAction, remindAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        UNUserNotificationCenter.current().setNotificationCategories([medicationCategory])
    }
}
