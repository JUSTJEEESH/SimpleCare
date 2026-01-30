import SwiftUI
@preconcurrency import SwiftData

struct MedicationListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<Medication> { $0.isActive },
           sort: \Medication.name)
    private var activeMedications: [Medication]

    @State private var showAddMedication = false
    @State private var selectedMedication: Medication?

    var body: some View {
        NavigationStack {
            Group {
                if activeMedications.isEmpty {
                    emptyState
                } else {
                    medicationList
                }
            }
            .background(SimpleCareColors.warmBackground)
            .navigationTitle("Medications")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddMedication = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(SimpleCareColors.calmBlue)
                    }
                    .accessibilityLabel("Add medication")
                }
            }
            .sheet(isPresented: $showAddMedication) {
                AddMedicationFlowView()
            }
            .sheet(item: $selectedMedication) { medication in
                MedicationDetailView(medication: medication)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "pills.fill")
                .font(.system(size: 48))
                .foregroundStyle(SimpleCareColors.sage.opacity(0.5))

            Text("No medications yet")
                .font(.title3.weight(.medium))
                .foregroundStyle(SimpleCareColors.charcoal)

            Text("Add your first medication to get started.")
                .font(.body)
                .foregroundStyle(SimpleCareColors.secondaryText)
                .multilineTextAlignment(.center)

            Button("Add Medication") {
                showAddMedication = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 48)
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Medication List

    private var medicationList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(activeMedications, id: \.id) { medication in
                    MedicationRowView(medication: medication)
                        .onTapGesture {
                            CalmHaptics.selection()
                            selectedMedication = medication
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Medication Row

struct MedicationRowView: View {
    let medication: Medication

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(SimpleCareColors.sage.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "pills.fill")
                        .foregroundStyle(SimpleCareColors.sage)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(medication.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(SimpleCareColors.charcoal)

                    if medication.isCritical {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(SimpleCareColors.calmBlue)
                    }
                }

                if !medication.dosage.isEmpty {
                    Text(medication.dosage)
                        .font(.subheadline)
                        .foregroundStyle(SimpleCareColors.secondaryText)
                }

                if !medication.scheduleTimes.isEmpty {
                    Text(scheduleDescription)
                        .font(.caption)
                        .foregroundStyle(SimpleCareColors.calmBlue)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SimpleCareColors.secondaryText.opacity(0.5))
        }
        .padding(16)
        .background(SimpleCareColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(medication.name), \(medication.dosage). \(scheduleDescription)")
    }

    private var scheduleDescription: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let times = medication.scheduleTimes.map { formatter.string(from: $0) }
        return times.joined(separator: ", ")
    }
}

#Preview {
    MedicationListView()
        .modelContainer(for: [Medication.self, MedicationLog.self], inMemory: true)
}
