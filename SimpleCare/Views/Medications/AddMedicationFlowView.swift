import SwiftUI
import SwiftData

struct AddMedicationFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var currentStep = 0
    @State private var medicationName = ""
    @State private var dosage = ""
    @State private var scheduleTimes: [Date] = [
        Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    ]
    @State private var notes = ""
    @State private var isCritical = false
    @State private var showCompletion = false

    private let totalSteps = 4

    var body: some View {
        NavigationStack {
            ZStack {
                SimpleCareColors.warmBackground
                    .ignoresSafeArea()

                if showCompletion {
                    completionView
                        .transition(.opacity)
                } else {
                    VStack(spacing: 0) {
                        // Progress indicator
                        progressBar
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        // Step content
                        TabView(selection: $currentStep) {
                            stepNameView.tag(0)
                            stepDosageView.tag(1)
                            stepScheduleView.tag(2)
                            stepNotesView.tag(3)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(SimpleCareColors.secondaryText)
                }
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SimpleCareColors.sageLight)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(SimpleCareColors.sage)
                        .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps), height: 6)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .frame(height: 6)

            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.caption)
                .foregroundStyle(SimpleCareColors.secondaryText)
        }
    }

    // MARK: - Step 1: Name

    private var stepNameView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("What is the medication name?")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(SimpleCareColors.charcoal)
                    .multilineTextAlignment(.center)

                TextField("Medication name", text: $medicationName)
                    .font(.title3)
                    .foregroundStyle(SimpleCareColors.charcoal)
                    .multilineTextAlignment(.center)
                    .textContentType(.name)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(SimpleCareColors.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(SimpleCareColors.sage.opacity(0.4), lineWidth: 1.5)
                    )
                    .padding(.horizontal, 32)
                    .submitLabel(.next)
                    .onSubmit { advanceStep() }
            }

            Spacer()

            nextButton(enabled: !medicationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Spacer().frame(height: 20)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Step 2: Dosage

    private var stepDosageView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("How much do you take?")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(SimpleCareColors.charcoal)
                    .multilineTextAlignment(.center)

                TextField("e.g., 1 tablet, 10mg", text: $dosage)
                    .font(.title3)
                    .foregroundStyle(SimpleCareColors.charcoal)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(SimpleCareColors.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(SimpleCareColors.sage.opacity(0.4), lineWidth: 1.5)
                    )
                    .padding(.horizontal, 32)
                    .submitLabel(.next)
                    .onSubmit { advanceStep() }

                Text("You can write this however makes sense to you.")
                    .font(.subheadline)
                    .foregroundStyle(SimpleCareColors.secondaryText)
            }

            Spacer()

            nextButton(enabled: true)

            Spacer().frame(height: 20)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Step 3: Schedule

    private var stepScheduleView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer().frame(height: 16)

                Text("When do you take it?")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(SimpleCareColors.charcoal)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    ForEach(scheduleTimes.indices, id: \.self) { index in
                        HStack(spacing: 12) {
                            Text("Time \(index + 1)")
                                .font(.body.weight(.medium))
                                .foregroundStyle(SimpleCareColors.charcoal)

                            Spacer()

                            DatePicker(
                                "Time \(index + 1)",
                                selection: $scheduleTimes[index],
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .scaleEffect(1.2)
                            .tint(SimpleCareColors.calmBlue)

                            if scheduleTimes.count > 1 {
                                Button {
                                    scheduleTimes.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(SimpleCareColors.destructive)
                                        .font(.title2)
                                }
                                .accessibilityLabel("Remove time \(index + 1)")
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 18)
                        .background(SimpleCareColors.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 24)

                Button {
                    let newTime = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
                    scheduleTimes.append(newTime)
                    CalmHaptics.selection()
                } label: {
                    Label("Add another time", systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(SimpleCareColors.calmBlue)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .background(SimpleCareColors.calmBlueLight)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)

                // Important medication toggle — highly visible
                HStack(spacing: 14) {
                    Image(systemName: isCritical ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundStyle(isCritical ? SimpleCareColors.calmBlue : SimpleCareColors.secondaryText)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Important medication")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(SimpleCareColors.charcoal)
                        Text("Family will be gently notified if missed")
                            .font(.subheadline)
                            .foregroundStyle(SimpleCareColors.secondaryText)
                    }

                    Spacer()

                    Toggle("", isOn: $isCritical)
                        .tint(SimpleCareColors.calmBlue)
                        .labelsHidden()
                }
                .padding(18)
                .background(isCritical ? SimpleCareColors.calmBlueLight : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.2), value: isCritical)

                nextButton(enabled: !scheduleTimes.isEmpty)

                Spacer().frame(height: 20)
            }
        }
        .padding(.horizontal, 0)
    }

    // MARK: - Step 4: Notes

    private var stepNotesView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("Any notes?")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(SimpleCareColors.charcoal)
                    .multilineTextAlignment(.center)

                Text("This is optional")
                    .font(.subheadline)
                    .foregroundStyle(SimpleCareColors.secondaryText)

                TextEditor(text: $notes)
                    .font(.body)
                    .foregroundStyle(SimpleCareColors.charcoal)
                    .scrollContentBackground(.hidden)
                    .frame(height: 120)
                    .padding(12)
                    .background(SimpleCareColors.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(SimpleCareColors.sage.opacity(0.4), lineWidth: 1.5)
                    )
                    .padding(.horizontal, 32)

                Text("e.g., Take with food, Take before bed")
                    .font(.caption)
                    .foregroundStyle(SimpleCareColors.secondaryText)
            }

            Spacer()

            Button("Save Medication") {
                saveMedication()
            }
            .buttonStyle(PrimaryButtonStyle(backgroundColor: SimpleCareColors.sage))
            .padding(.horizontal, 32)

            Spacer().frame(height: 20)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(SimpleCareColors.sage)

            Text("You're all set.")
                .font(.title.weight(.semibold))
                .foregroundStyle(SimpleCareColors.charcoal)

            Text("\(medicationName) has been added.")
                .font(.body)
                .foregroundStyle(SimpleCareColors.charcoalLight)

            Spacer()

            Button("Done") {
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 32)

            Spacer().frame(height: 40)
        }
    }

    // MARK: - Helpers

    private func nextButton(enabled: Bool) -> some View {
        Button("Next") {
            advanceStep()
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal, 32)
        .opacity(enabled ? 1.0 : 0.5)
        .disabled(!enabled)
    }

    private func advanceStep() {
        CalmHaptics.selection()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = min(currentStep + 1, totalSteps - 1)
        }
    }

    private func saveMedication() {
        let medication = Medication(
            name: medicationName.trimmingCharacters(in: .whitespacesAndNewlines),
            dosage: dosage.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            scheduleTimes: scheduleTimes,
            isCritical: isCritical
        )
        modelContext.insert(medication)

        // Create today's logs for this medication
        let calendar = Calendar.current
        let today = Date()
        for time in scheduleTimes {
            let hour = calendar.component(.hour, from: time)
            let minute = calendar.component(.minute, from: time)
            if let scheduledDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) {
                let log = MedicationLog(medication: medication, scheduledTime: scheduledDate)
                modelContext.insert(log)
            }
        }

        try? modelContext.save()

        // Schedule notifications
        NotificationService.shared.scheduleMedicationReminders(for: medication)

        CalmHaptics.gentle()

        withAnimation(.easeInOut(duration: 0.4)) {
            showCompletion = true
        }
    }
}

#Preview {
    AddMedicationFlowView()
        .modelContainer(for: [Medication.self, MedicationLog.self], inMemory: true)
}
