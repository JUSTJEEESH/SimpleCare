import SwiftUI
@preconcurrency import SwiftData

struct MedicationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var medication: Medication

    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    @State private var recentLogs: [MedicationLog] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Medication Info Card
                    infoCard
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    // Schedule Card
                    scheduleCard
                        .padding(.horizontal, 20)

                    // Recent History
                    if !recentLogs.isEmpty {
                        historyCard
                            .padding(.horizontal, 20)
                    }

                    // Actions
                    actionsSection
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    Spacer(minLength: 32)
                }
            }
            .background(SimpleCareColors.warmBackground)
            .navigationTitle(medication.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Edit") {
                        showEditSheet = true
                    }
                    .foregroundStyle(SimpleCareColors.calmBlue)
                    .font(.body.weight(.medium))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(SimpleCareColors.calmBlue)
                }
            }
            .sheet(isPresented: $showEditSheet) {
                loadRecentLogs()
            } content: {
                EditMedicationView(medication: medication)
            }
            .alert("Remove Medication", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    deleteMedication()
                }
            } message: {
                Text("This will remove \(medication.name) and all its history. This cannot be undone.")
            }
            .onAppear {
                loadRecentLogs()
            }
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let photoData = medication.photoData, let uiImage = UIImage(data: photoData) {
                HStack {
                    Spacer()
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Spacer()
                }
                .padding(.bottom, 4)
            }

            if !medication.dosage.isEmpty {
                detailRow(title: "Dosage", value: medication.dosage)
            }

            if !medication.notes.isEmpty {
                detailRow(title: "Notes", value: medication.notes)
            }

            if medication.isCritical {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(SimpleCareColors.heartRed)
                    Text("Important medication")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SimpleCareColors.heartRed)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(SimpleCareColors.heartRedLight)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gentleCard()
    }

    // MARK: - Schedule Card

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schedule")
                .font(.headline)
                .foregroundStyle(SimpleCareColors.charcoal)

            let formatter = DateFormatter()
            let _ = formatter.timeStyle = .short

            ForEach(medication.scheduleTimes, id: \.self) { time in
                HStack(spacing: 10) {
                    Image(systemName: "clock")
                        .foregroundStyle(SimpleCareColors.calmBlue)
                    Text(formatter.string(from: time))
                        .font(.body)
                        .foregroundStyle(SimpleCareColors.charcoal)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gentleCard()
    }

    // MARK: - History Card

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent History")
                .font(.headline)
                .foregroundStyle(SimpleCareColors.charcoal)

            ForEach(recentLogs.prefix(7), id: \.id) { log in
                HStack(spacing: 12) {
                    Circle()
                        .fill(statusColor(for: log.logStatus))
                        .frame(width: 10, height: 10)

                    Text(dateString(from: log.scheduledTime))
                        .font(.subheadline)
                        .foregroundStyle(SimpleCareColors.charcoal)

                    Spacer()

                    Text(log.logStatus.rawValue.capitalized)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(statusColor(for: log.logStatus))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gentleCard()
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                showEditSheet = true
            } label: {
                Label("Edit Medication", systemImage: "pencil")
                    .font(.body.weight(.medium))
                    .foregroundStyle(SimpleCareColors.calmBlue)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .background(SimpleCareColors.calmBlueLight)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button {
                showDeleteConfirmation = true
            } label: {
                Text("Remove Medication")
                    .font(.body)
                    .foregroundStyle(SimpleCareColors.destructive)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .background(SimpleCareColors.destructive.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - Helpers

    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(SimpleCareColors.secondaryText)
            Text(value)
                .font(.body)
                .foregroundStyle(SimpleCareColors.charcoal)
        }
    }

    private func statusColor(for status: LogStatus) -> Color {
        switch status {
        case .taken: return SimpleCareColors.taken
        case .skipped: return SimpleCareColors.skipped
        case .upcoming: return SimpleCareColors.upcoming
        }
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func loadRecentLogs() {
        let medId = medication.id
        let descriptor = FetchDescriptor<MedicationLog>(
            predicate: #Predicate<MedicationLog> { log in
                log.medication?.id == medId
            },
            sortBy: [SortDescriptor(\.scheduledTime, order: .reverse)]
        )
        recentLogs = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func deleteMedication() {
        medication.isActive = false
        try? modelContext.save()
        NotificationService.shared.cancelReminders(for: medication)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Medication.self, MedicationLog.self, configurations: config)
    let med = Medication(name: "Lisinopril", dosage: "10mg tablet", notes: "Take with food")
    container.mainContext.insert(med)

    return MedicationDetailView(medication: med)
        .modelContainer(container)
}
