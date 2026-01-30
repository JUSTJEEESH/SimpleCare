import SwiftUI
@preconcurrency import SwiftData

struct MedicationLogView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate = Date()
    @State private var logs: [MedicationLog] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Date picker
                    DatePicker(
                        "Select date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    if logs.isEmpty {
                        VStack(spacing: 12) {
                            Spacer().frame(height: 40)
                            Text("No medications recorded for this day.")
                                .font(.body)
                                .foregroundStyle(SimpleCareColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        // Timeline
                        LazyVStack(spacing: 0) {
                            ForEach(logs, id: \.id) { log in
                                logTimelineRow(log)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 32)
                }
            }
            .background(SimpleCareColors.warmBackground)
            .navigationTitle("Medication Log")
            .onChange(of: selectedDate) { _, _ in
                loadLogs()
            }
            .onAppear {
                loadLogs()
            }
        }
    }

    private func logTimelineRow(_ log: MedicationLog) -> some View {
        HStack(spacing: 14) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(statusColor(for: log.logStatus))
                    .frame(width: 14, height: 14)
                Rectangle()
                    .fill(SimpleCareColors.upcoming.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 14)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(log.medication?.name ?? "Medication")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(SimpleCareColors.charcoal)

                HStack(spacing: 8) {
                    Text(timeString(from: log.scheduledTime))
                        .font(.subheadline)
                        .foregroundStyle(SimpleCareColors.secondaryText)

                    Text(log.logStatus.rawValue.capitalized)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(statusColor(for: log.logStatus))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor(for: log.logStatus).opacity(0.15))
                        .clipShape(Capsule())
                }

                if let med = log.medication, !med.dosage.isEmpty {
                    Text(med.dosage)
                        .font(.caption)
                        .foregroundStyle(SimpleCareColors.secondaryText)
                }
            }

            Spacer()

            // Action buttons for upcoming
            if log.logStatus == .upcoming {
                Button {
                    markAsTaken(log)
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(SimpleCareColors.taken)
                }
                .accessibilityLabel("Mark as taken")
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private func statusColor(for status: LogStatus) -> Color {
        switch status {
        case .taken: return SimpleCareColors.taken
        case .skipped: return SimpleCareColors.skipped
        case .upcoming: return SimpleCareColors.upcoming
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func markAsTaken(_ log: MedicationLog) {
        log.logStatus = .taken
        log.actionTime = Date()
        CalmHaptics.gentle()
        try? modelContext.save()
        loadLogs()
    }

    private func loadLogs() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = startOfDay.addingTimeInterval(86400)

        let descriptor = FetchDescriptor<MedicationLog>(
            predicate: #Predicate<MedicationLog> {
                $0.scheduledTime >= startOfDay && $0.scheduledTime < endOfDay
            },
            sortBy: [SortDescriptor(\.scheduledTime)]
        )
        logs = (try? modelContext.fetch(descriptor)) ?? []
    }
}

#Preview {
    MedicationLogView()
        .modelContainer(for: [Medication.self, MedicationLog.self], inMemory: true)
}
