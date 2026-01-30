import Foundation
import SwiftData

final class DailyLogService {
    static let shared = DailyLogService()

    private init() {}

    /// Creates medication logs for today for all active medications.
    /// Should be called on app launch and when the day changes.
    func createTodayLogs(context: ModelContext) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = startOfDay.addingTimeInterval(86400)

        // Fetch active medications
        let medDescriptor = FetchDescriptor<Medication>(
            predicate: #Predicate<Medication> { $0.isActive }
        )
        guard let medications = try? context.fetch(medDescriptor) else { return }

        // Fetch existing logs for today
        let logDescriptor = FetchDescriptor<MedicationLog>(
            predicate: #Predicate<MedicationLog> {
                $0.scheduledTime >= startOfDay && $0.scheduledTime < endOfDay
            }
        )
        let existingLogs = (try? context.fetch(logDescriptor)) ?? []
        let existingMedIds = Set(existingLogs.compactMap { $0.medication?.id })

        // Create logs for medications that don't have today's logs yet
        for medication in medications {
            guard !existingMedIds.contains(medication.id) else { continue }

            for time in medication.scheduleTimes {
                let hour = calendar.component(.hour, from: time)
                let minute = calendar.component(.minute, from: time)
                if let scheduledDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) {
                    let log = MedicationLog(medication: medication, scheduledTime: scheduledDate)
                    context.insert(log)
                }
            }
        }

        try? context.save()
    }
}
