import SwiftUI
import SwiftData

struct AddAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var doctorName = ""
    @State private var dateTime = Date()
    @State private var location = ""
    @State private var notes = ""
    @State private var prepReminder = false
    @State private var prepReminderMinutes = 60
    @State private var showCompletion = false

    private let prepOptions = [15, 30, 60, 120, 1440] // minutes

    var body: some View {
        NavigationStack {
            ZStack {
                SimpleCareColors.warmBackground
                    .ignoresSafeArea()

                if showCompletion {
                    completionView
                        .transition(.opacity)
                } else {
                    formContent
                }
            }
            .navigationTitle("Add Appointment")
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

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title / Doctor
                VStack(alignment: .leading, spacing: 8) {
                    Text("What is this appointment for?")
                        .font(.body.weight(.medium))
                        .foregroundStyle(SimpleCareColors.charcoal)

                    TextField("e.g., Annual checkup", text: $title)
                        .font(.body)
                        .foregroundStyle(SimpleCareColors.charcoal)
                        .padding(14)
                        .background(SimpleCareColors.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Doctor or provider")
                        .font(.body.weight(.medium))
                        .foregroundStyle(SimpleCareColors.charcoal)

                    TextField("e.g., Dr. Smith", text: $doctorName)
                        .font(.body)
                        .foregroundStyle(SimpleCareColors.charcoal)
                        .textContentType(.name)
                        .padding(14)
                        .background(SimpleCareColors.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // Date & Time
                VStack(alignment: .leading, spacing: 8) {
                    Text("When?")
                        .font(.body.weight(.medium))
                        .foregroundStyle(SimpleCareColors.charcoal)

                    DatePicker(
                        "Appointment date and time",
                        selection: $dateTime,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SimpleCareColors.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // Location (optional)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Location")
                            .font(.body.weight(.medium))
                            .foregroundStyle(SimpleCareColors.charcoal)
                        Text("Optional")
                            .font(.caption)
                            .foregroundStyle(SimpleCareColors.secondaryText)
                    }

                    TextField("e.g., 123 Main St", text: $location)
                        .font(.body)
                        .foregroundStyle(SimpleCareColors.charcoal)
                        .textContentType(.fullStreetAddress)
                        .padding(14)
                        .background(SimpleCareColors.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // Notes (optional)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Notes")
                            .font(.body.weight(.medium))
                            .foregroundStyle(SimpleCareColors.charcoal)
                        Text("Optional")
                            .font(.caption)
                            .foregroundStyle(SimpleCareColors.secondaryText)
                    }

                    TextField("e.g., Bring insurance card", text: $notes)
                        .font(.body)
                        .foregroundStyle(SimpleCareColors.charcoal)
                        .padding(14)
                        .background(SimpleCareColors.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // Prep Reminder
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 14) {
                        Image(systemName: prepReminder ? "bell.fill" : "bell")
                            .font(.title3)
                            .foregroundStyle(prepReminder ? SimpleCareColors.calmBlue : SimpleCareColors.secondaryText)

                        Text("Preparation reminder")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(SimpleCareColors.charcoal)

                        Spacer()

                        Toggle("", isOn: $prepReminder)
                            .tint(SimpleCareColors.calmBlue)
                            .labelsHidden()
                    }

                    if prepReminder {
                        Picker("Remind me", selection: $prepReminderMinutes) {
                            Text("15 minutes before").tag(15)
                            Text("30 minutes before").tag(30)
                            Text("1 hour before").tag(60)
                            Text("2 hours before").tag(120)
                            Text("1 day before").tag(1440)
                        }
                        .pickerStyle(.menu)
                        .tint(SimpleCareColors.calmBlue)
                        .font(.body)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SimpleCareColors.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(16)
                .background(prepReminder ? SimpleCareColors.calmBlueLight : SimpleCareColors.sageLight)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .animation(.easeInOut(duration: 0.2), value: prepReminder)

                // Save Button
                Button("Save Appointment") {
                    saveAppointment()
                }
                .buttonStyle(PrimaryButtonStyle(backgroundColor: SimpleCareColors.calmBlue))
                .padding(.top, 8)
                .opacity(canSave ? 1.0 : 0.5)
                .disabled(!canSave)

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(SimpleCareColors.calmBlue)

            Text("Appointment saved.")
                .font(.title.weight(.semibold))
                .foregroundStyle(SimpleCareColors.charcoal)

            if !title.isEmpty {
                Text(title)
                    .font(.body)
                    .foregroundStyle(SimpleCareColors.charcoalLight)
            }

            Spacer()

            Button("Done") {
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 32)

            Spacer().frame(height: 40)
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !doctorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveAppointment() {
        let appointment = Appointment(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            doctorName: doctorName.trimmingCharacters(in: .whitespacesAndNewlines),
            dateTime: dateTime,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            prepReminder: prepReminder,
            prepReminderMinutes: prepReminderMinutes
        )
        modelContext.insert(appointment)
        try? modelContext.save()

        NotificationService.shared.scheduleAppointmentReminder(for: appointment)

        CalmHaptics.gentle()

        withAnimation(.easeInOut(duration: 0.4)) {
            showCompletion = true
        }
    }
}

#Preview {
    AddAppointmentView()
        .modelContainer(for: Appointment.self, inMemory: true)
}
