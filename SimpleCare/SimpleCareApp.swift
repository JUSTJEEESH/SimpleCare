import SwiftUI
import SwiftData

@main
struct SimpleCareApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @AppStorage("appearanceMode") private var appearanceMode = 0

    private let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Medication.self,
                MedicationLog.self,
                Appointment.self,
                HealthNote.self,
                CareCircleMember.self
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

    private var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
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
            .preferredColorScheme(preferredColorScheme)
        }
    }
}
