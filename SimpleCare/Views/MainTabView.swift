import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            MedicationListView()
                .tabItem {
                    Label("Medications", systemImage: "pills.fill")
                }
                .tag(1)

            AppointmentListView()
                .tabItem {
                    Label("Appointments", systemImage: "calendar")
                }
                .tag(2)

            NotesListView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(SimpleCareColors.calmBlue)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Medication.self, MedicationLog.self, Appointment.self, HealthNote.self], inMemory: true)
}
