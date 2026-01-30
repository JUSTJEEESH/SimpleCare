import SwiftUI
@preconcurrency import SwiftData
import WidgetKit

struct HomeView: View {
    @AppStorage("userName") private var userName = ""
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<Medication> { $0.isActive },
           sort: \Medication.name)
    private var medications: [Medication]

    @Query(sort: \Appointment.dateTime)
    private var allAppointments: [Appointment]

    @Query(sort: \CareCircleMember.createdAt)
    private var careCircleMembers: [CareCircleMember]

    @State private var showAddMedication = false
    @State private var showAddAppointment = false
    @State private var showCircleOfCare = false
    @State private var todayLogs: [MedicationLog] = []

    private var upcomingAppointments: [Appointment] {
        let now = Date()
        let endOfDay = Calendar.current.startOfDay(for: now).addingTimeInterval(86400)
        return allAppointments.filter { $0.dateTime >= now && $0.dateTime < endOfDay && !$0.isCompleted }
    }

    private var pendingLogs: [MedicationLog] {
        todayLogs.filter { $0.logStatus == .upcoming }
    }

    private var takenCount: Int {
        todayLogs.filter { $0.logStatus == .taken }.count
    }

    private var totalScheduled: Int {
        todayLogs.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Card
                    heroCard
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Next Medication
                    if let nextLog = pendingLogs.first {
                        nextMedicationCard(nextLog)
                            .padding(.horizontal, 20)
                    }

                    // Today's Appointments
                    if !upcomingAppointments.isEmpty {
                        appointmentCard
                            .padding(.horizontal, 20)
                    }

                    // Quick Actions
                    quickActions
                        .padding(.horizontal, 20)

                    // Circle of Care quick access
                    if !careCircleMembers.isEmpty {
                        careCircleCard
                            .padding(.horizontal, 20)
                    }

                    // Today's Progress
                    if !todayLogs.isEmpty {
                        todayProgressSection
                            .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top, 8)
            }
            .background(SimpleCareColors.warmBackground)
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddMedication) {
                AddMedicationFlowView()
            }
            .sheet(isPresented: $showAddAppointment) {
                AddAppointmentView()
            }
            .sheet(isPresented: $showCircleOfCare) {
                CircleOfCareView()
            }
            .onAppear {
                refreshTodayLogs()
            }
            .refreshable {
                refreshTodayLogs()
            }
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(heroMessage)
                .font(.title3.weight(.medium))
                .foregroundStyle(SimpleCareColors.charcoal)
                .lineSpacing(4)

            if totalScheduled > 0 {
                HStack(spacing: 4) {
                    Text("\(takenCount) of \(totalScheduled)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SimpleCareColors.sage)
                    Text("medications taken today")
                        .font(.subheadline)
                        .foregroundStyle(SimpleCareColors.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gentleCard()
        .accessibilityElement(children: .combine)
    }

    private var heroMessage: String {
        let pendingCount = pendingLogs.count

        switch TimeOfDay.current {
        case .morning:
            if pendingCount > 0 {
                return "You have \(pendingCount) medication\(pendingCount == 1 ? "" : "s") to take this morning."
            }
            return "You're all set for this morning."

        case .midday, .afternoon:
            if let next = pendingLogs.first, let med = next.medication {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Next up: \(med.name) at \(formatter.string(from: next.scheduledTime))."
            }
            if !upcomingAppointments.isEmpty {
                let apt = upcomingAppointments[0]
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "\(apt.title.isEmpty ? apt.doctorName : apt.title) today at \(formatter.string(from: apt.dateTime))."
            }
            return "Everything looks good today."

        case .evening, .night:
            if pendingCount == 0 {
                return "You're all set for today. Rest well."
            }
            return "You have \(pendingCount) medication\(pendingCount == 1 ? "" : "s") left for today."
        }
    }

    // MARK: - Next Medication Card

    private func nextMedicationCard(_ log: MedicationLog) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                if let med = log.medication, let photoData = med.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Medication")
                        .font(.subheadline)
                        .foregroundStyle(SimpleCareColors.secondaryText)
                    Text(log.medication?.name ?? "Medication")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(SimpleCareColors.charcoal)
                    if let med = log.medication, !med.dosage.isEmpty {
                        Text(med.dosage)
                            .font(.body)
                            .foregroundStyle(SimpleCareColors.charcoalLight)
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(timeString(from: log.scheduledTime))
                        .font(.title2.weight(.medium))
                        .foregroundStyle(SimpleCareColors.calmBlue)
                }
            }

            // Action buttons — large, obvious
            HStack(spacing: 12) {
                Button {
                    markAsTaken(log)
                } label: {
                    Label("Taken", systemImage: "checkmark.circle.fill")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                }
                .buttonStyle(PrimaryButtonStyle(backgroundColor: SimpleCareColors.taken))

                Menu {
                    Button("Skip") {
                        markAsSkipped(log)
                    }
                    Button("Remind Me Later") {
                        // Schedule a local reminder for 15 min later
                        CalmHaptics.selection()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundStyle(SimpleCareColors.secondaryText)
                        .frame(width: 52, height: 52)
                        .background(SimpleCareColors.sageLight)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .gentleCard()
        .accessibilityElement(children: .contain)
    }

    // MARK: - Appointment Card

    private var appointmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Appointment")
                .font(.subheadline)
                .foregroundStyle(SimpleCareColors.secondaryText)

            ForEach(upcomingAppointments, id: \.id) { appointment in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appointment.title.isEmpty ? appointment.doctorName : appointment.title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(SimpleCareColors.charcoal)
                        if !appointment.location.isEmpty {
                            Text(appointment.location)
                                .font(.subheadline)
                                .foregroundStyle(SimpleCareColors.secondaryText)
                        }
                    }
                    Spacer()
                    Text(timeString(from: appointment.dateTime))
                        .font(.body.weight(.medium))
                        .foregroundStyle(SimpleCareColors.calmBlue)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gentleCard()
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 14) {
            quickActionButton(
                title: "Add\nMedication",
                icon: "pills.fill",
                color: SimpleCareColors.sage
            ) {
                showAddMedication = true
            }

            quickActionButton(
                title: "Add\nAppointment",
                icon: "calendar.badge.plus",
                color: SimpleCareColors.calmBlue
            ) {
                showAddAppointment = true
            }
        }
    }

    private func quickActionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            CalmHaptics.selection()
            action()
        }) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SimpleCareColors.charcoal)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 100)
            .background(SimpleCareColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
        .accessibilityLabel(title.replacingOccurrences(of: "\n", with: " "))
    }

    // MARK: - Today's Progress

    private var todayProgressSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today's Medications")
                .font(.headline)
                .foregroundStyle(SimpleCareColors.charcoal)

            ForEach(todayLogs, id: \.id) { log in
                HStack(spacing: 14) {
                    Circle()
                        .fill(statusColor(for: log.logStatus))
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.medication?.name ?? "Medication")
                            .font(.body.weight(.medium))
                            .foregroundStyle(SimpleCareColors.charcoal)
                        Text(timeString(from: log.scheduledTime))
                            .font(.subheadline)
                            .foregroundStyle(SimpleCareColors.secondaryText)
                    }

                    Spacer()

                    Text(log.logStatus.rawValue.capitalized)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(statusColor(for: log.logStatus))
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(log.medication?.name ?? "Medication") at \(timeString(from: log.scheduledTime)). \(log.logStatus.rawValue)")
            }
        }
        .gentleCard()
    }

    // MARK: - Circle of Care Card

    private var careCircleCard: some View {
        Button {
            showCircleOfCare = true
            CalmHaptics.selection()
        } label: {
            HStack(spacing: 14) {
                HStack(spacing: -6) {
                    ForEach(careCircleMembers.prefix(3), id: \.id) { member in
                        let initials = member.name.split(separator: " ")
                            .prefix(2).compactMap { $0.first }.map { String($0) }.joined().uppercased()
                        Text(initials.isEmpty ? "?" : initials)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(SimpleCareColors.calmBlue)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(SimpleCareColors.cardBackground, lineWidth: 2))
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Circle of Care")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SimpleCareColors.charcoal)
                    Text("\(careCircleMembers.count) \(careCircleMembers.count == 1 ? "person" : "people") watching over you")
                        .font(.caption)
                        .foregroundStyle(SimpleCareColors.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(SimpleCareColors.secondaryText)
            }
        }
        .padding(16)
        .background(SimpleCareColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: - Helpers

    private var navTitle: String {
        if userName.isEmpty {
            return "Home"
        }
        return "Hi, \(userName)"
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func statusColor(for status: LogStatus) -> Color {
        switch status {
        case .taken: return SimpleCareColors.taken
        case .skipped: return SimpleCareColors.skipped
        case .upcoming: return SimpleCareColors.upcoming
        }
    }

    private func markAsTaken(_ log: MedicationLog) {
        log.logStatus = .taken
        log.actionTime = Date()
        CalmHaptics.gentle()
        try? modelContext.save()
        refreshTodayLogs()
    }

    private func markAsSkipped(_ log: MedicationLog) {
        log.logStatus = .skipped
        log.actionTime = Date()
        CalmHaptics.selection()
        try? modelContext.save()
        refreshTodayLogs()
    }

    private func refreshTodayLogs() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = startOfDay.addingTimeInterval(86400)

        let descriptor = FetchDescriptor<MedicationLog>(
            predicate: #Predicate<MedicationLog> {
                $0.scheduledTime >= startOfDay && $0.scheduledTime < endOfDay
            },
            sortBy: [SortDescriptor(\.scheduledTime)]
        )

        todayLogs = (try? modelContext.fetch(descriptor)) ?? []
        updateWidgetData()
    }

    private func updateWidgetData() {
        let defaults = UserDefaults(suiteName: "group.com.simplecare.shared")
        defaults?.set(userName, forKey: "widgetUserName")
        defaults?.set(takenCount, forKey: "widgetTakenCount")
        defaults?.set(totalScheduled, forKey: "widgetTotalCount")

        if let nextLog = pendingLogs.first {
            defaults?.set(nextLog.medication?.name ?? "", forKey: "widgetNextMedName")
            defaults?.set(nextLog.medication?.dosage ?? "", forKey: "widgetNextMedDosage")
            defaults?.set(nextLog.scheduledTime, forKey: "widgetNextMedTime")
        } else {
            defaults?.removeObject(forKey: "widgetNextMedName")
            defaults?.removeObject(forKey: "widgetNextMedDosage")
            defaults?.removeObject(forKey: "widgetNextMedTime")
        }

        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Medication.self, MedicationLog.self, Appointment.self, HealthNote.self, CareCircleMember.self], inMemory: true)
}
