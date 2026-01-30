import SwiftUI
import SwiftData

@main
struct SimpleCareApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("appLockEnabled") private var appLockEnabled = false

    private let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Medication.self,
                MedicationLog.self,
                Appointment.self,
                HealthNote.self
            ])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .modelContainer(modelContainer)
                    .onAppear {
                        DailyLogService.shared.createTodayLogs(
                            context: modelContainer.mainContext
                        )
                    }
            } else {
                OnboardingFlowView()
                    .modelContainer(modelContainer)
            }
        }
    }
}
