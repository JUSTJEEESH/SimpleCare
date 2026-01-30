import SwiftUI
@preconcurrency import SwiftData
import LocalAuthentication

struct SettingsView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("appearanceMode") private var appearanceMode = 0 // 0=system, 1=light, 2=dark

    @Environment(\.modelContext) private var modelContext
    @State private var showExportSheet = false
    @State private var showCircleOfCare = false
    @State private var showResetConfirmation = false
    @State private var editedName = ""
    @State private var exportPDFData: Data?

    @AppStorage("caregiverMode") private var caregiverMode = false
    @AppStorage("caregiverName") private var caregiverName = ""

    @Query(filter: #Predicate<Medication> { $0.isActive })
    private var medications: [Medication]

    @Query private var allLogs: [MedicationLog]
    @Query private var appointments: [Appointment]
    @Query private var notes: [HealthNote]
    @Query private var careCircleMembers: [CareCircleMember]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Section
                    profileSection
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    // Doctor's Report
                    reportSection
                        .padding(.horizontal, 20)

                    // Circle of Care
                    circleOfCareSection
                        .padding(.horizontal, 20)

                    // Security
                    securitySection
                        .padding(.horizontal, 20)

                    // Appearance
                    appearanceSection
                        .padding(.horizontal, 20)

                    // About
                    aboutSection
                        .padding(.horizontal, 20)

                    // Reset (bottom)
                    resetSection
                        .padding(.horizontal, 20)

                    Spacer(minLength: 32)
                }
            }
            .background(SimpleCareColors.warmBackground)
            .navigationTitle("Settings")
            .sheet(isPresented: $showCircleOfCare) {
                CircleOfCareView()
            }
            .sheet(isPresented: $showExportSheet) {
                if let data = exportPDFData {
                    ShareSheet(items: [data])
                }
            }
            .alert("Reset App", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset Everything", role: .destructive) {
                    resetApp()
                }
            } message: {
                Text("This will delete all your data and return to the welcome screen. This cannot be undone.")
            }
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Name")
                .font(.headline)
                .foregroundStyle(SimpleCareColors.charcoal)

            HStack {
                TextField("Your name", text: $userName)
                    .font(.body)
                    .foregroundStyle(SimpleCareColors.charcoal)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .gentleCard()
    }

    // MARK: - Doctor's Report

    private var reportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Doctor's Report")
                .font(.headline)
                .foregroundStyle(SimpleCareColors.charcoal)

            Text("Generate a clean PDF report of your last 30 days to share with your doctor.")
                .font(.subheadline)
                .foregroundStyle(SimpleCareColors.secondaryText)
                .lineSpacing(3)

            Button {
                generatePDF()
            } label: {
                Label("Export Report", systemImage: "doc.text.fill")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
            }
            .buttonStyle(PrimaryButtonStyle(backgroundColor: SimpleCareColors.calmBlue))
        }
        .gentleCard()
    }

    // MARK: - Circle of Care

    private var circleOfCareSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Circle of Care")
                    .font(.headline)
                    .foregroundStyle(SimpleCareColors.charcoal)
                Spacer()
                if !careCircleMembers.isEmpty {
                    Text("\(careCircleMembers.count) \(careCircleMembers.count == 1 ? "person" : "people")")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SimpleCareColors.calmBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(SimpleCareColors.calmBlueLight)
                        .clipShape(Capsule())
                }
            }

            if careCircleMembers.isEmpty {
                Text("Add family or caregivers who can help keep track of your care.")
                    .font(.subheadline)
                    .foregroundStyle(SimpleCareColors.secondaryText)
                    .lineSpacing(3)
            } else {
                // Show member names
                HStack(spacing: -8) {
                    ForEach(careCircleMembers.prefix(4), id: \.id) { member in
                        let initials = member.name.split(separator: " ")
                            .prefix(2).compactMap { $0.first }.map { String($0) }.joined().uppercased()
                        Text(initials.isEmpty ? "?" : initials)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(SimpleCareColors.calmBlue)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                    }
                    if careCircleMembers.count > 4 {
                        Text("+\(careCircleMembers.count - 4)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(SimpleCareColors.sage)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                    }
                }
            }

            Button {
                showCircleOfCare = true
            } label: {
                Label(
                    careCircleMembers.isEmpty ? "Set Up Circle of Care" : "Manage Circle of Care",
                    systemImage: "person.2.fill"
                )
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
            }
            .buttonStyle(careCircleMembers.isEmpty
                ? PrimaryButtonStyle(backgroundColor: SimpleCareColors.calmBlue)
                : PrimaryButtonStyle(backgroundColor: SimpleCareColors.sage))
        }
        .gentleCard()
    }

    // MARK: - Security

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security")
                .font(.headline)
                .foregroundStyle(SimpleCareColors.charcoal)

            HStack(spacing: 14) {
                Image(systemName: appLockEnabled ? "lock.fill" : "lock.open")
                    .font(.title3)
                    .foregroundStyle(appLockEnabled ? SimpleCareColors.calmBlue : SimpleCareColors.secondaryText)

                VStack(alignment: .leading, spacing: 3) {
                    Text("App Lock")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(SimpleCareColors.charcoal)
                    Text("Require Face ID or Touch ID to open")
                        .font(.subheadline)
                        .foregroundStyle(SimpleCareColors.secondaryText)
                }

                Spacer()

                Toggle("", isOn: $appLockEnabled)
                    .tint(SimpleCareColors.calmBlue)
                    .labelsHidden()
            }
        }
        .gentleCard()
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(.headline)
                .foregroundStyle(SimpleCareColors.charcoal)

            Text("Choose how Simple Care looks.")
                .font(.subheadline)
                .foregroundStyle(SimpleCareColors.secondaryText)

            HStack(spacing: 10) {
                appearanceOption(title: "System", icon: "iphone", tag: 0)
                appearanceOption(title: "Light", icon: "sun.max.fill", tag: 1)
                appearanceOption(title: "Dark", icon: "moon.fill", tag: 2)
            }
        }
        .gentleCard()
    }

    private func appearanceOption(title: String, icon: String, tag: Int) -> some View {
        Button {
            appearanceMode = tag
            CalmHaptics.selection()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(appearanceMode == tag ? SimpleCareColors.calmBlue : SimpleCareColors.secondaryText)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(appearanceMode == tag ? SimpleCareColors.charcoal : SimpleCareColors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 70)
            .background(appearanceMode == tag ? SimpleCareColors.calmBlueLight : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(appearanceMode == tag ? SimpleCareColors.calmBlue : Color.clear, lineWidth: 2)
            )
        }
        .accessibilityLabel("\(title) mode")
        .accessibilityAddTraits(appearanceMode == tag ? .isSelected : [])
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About Simple Care")
                .font(.headline)
                .foregroundStyle(SimpleCareColors.charcoal)

            VStack(alignment: .leading, spacing: 8) {
                aboutRow("Version", value: "1.0.0")
                aboutRow("Data", value: "Stored on this device only")
                aboutRow("Privacy", value: "No tracking. No accounts. No ads.")
            }
        }
        .gentleCard()
    }

    private func aboutRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(SimpleCareColors.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(SimpleCareColors.charcoal)
        }
    }

    // MARK: - Reset

    private var resetSection: some View {
        Button {
            showResetConfirmation = true
        } label: {
            Text("Reset All Data")
                .font(.body)
                .foregroundStyle(SimpleCareColors.destructive)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .background(SimpleCareColors.destructive.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Actions

    private func generatePDF() {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        let recentLogs = allLogs.filter { $0.scheduledTime >= cutoffDate }

        let data = PDFExportService.shared.generateReport(
            userName: userName,
            medications: Array(medications),
            logs: recentLogs,
            appointments: Array(appointments),
            notes: Array(notes),
            days: 30
        )

        exportPDFData = data
        showExportSheet = true
        CalmHaptics.gentle()
    }

    private func resetApp() {
        // Delete all data
        try? modelContext.delete(model: Medication.self)
        try? modelContext.delete(model: MedicationLog.self)
        try? modelContext.delete(model: Appointment.self)
        try? modelContext.delete(model: HealthNote.self)
        try? modelContext.delete(model: CareCircleMember.self)
        try? modelContext.save()

        // Cancel all notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        // Reset user defaults
        userName = ""
        appLockEnabled = false
        caregiverMode = false
        caregiverName = ""
        hasCompletedOnboarding = false
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: [Medication.self, MedicationLog.self, Appointment.self, HealthNote.self, CareCircleMember.self], inMemory: true)
}
