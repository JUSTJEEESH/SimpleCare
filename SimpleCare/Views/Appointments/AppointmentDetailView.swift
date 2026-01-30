import SwiftUI
import SwiftData

struct AppointmentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var appointment: Appointment

    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date & Time Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 14) {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundStyle(SimpleCareColors.calmBlue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(dateString)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(SimpleCareColors.charcoal)
                                Text(timeString)
                                    .font(.title2.weight(.medium))
                                    .foregroundStyle(SimpleCareColors.calmBlue)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .gentleCard()
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Details Card
                    VStack(alignment: .leading, spacing: 14) {
                        if !appointment.doctorName.isEmpty {
                            detailRow(icon: "person.fill", title: "Doctor", value: appointment.doctorName)
                        }

                        if !appointment.location.isEmpty {
                            detailRow(icon: "mappin.circle.fill", title: "Location", value: appointment.location)
                        }

                        if !appointment.notes.isEmpty {
                            detailRow(icon: "note.text", title: "Notes", value: appointment.notes)
                        }

                        if appointment.prepReminder {
                            detailRow(icon: "bell.fill", title: "Reminder", value: prepReminderText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .gentleCard()
                    .padding(.horizontal, 20)

                    // Actions
                    VStack(spacing: 12) {
                        if !appointment.isCompleted {
                            Button {
                                markCompleted()
                            } label: {
                                Label("Mark as Done", systemImage: "checkmark.circle")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 52)
                            }
                            .buttonStyle(PrimaryButtonStyle(backgroundColor: SimpleCareColors.taken))
                        }

                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Text("Remove Appointment")
                                .font(.body)
                                .foregroundStyle(SimpleCareColors.destructive)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 50)
                                .background(SimpleCareColors.destructive.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer(minLength: 32)
                }
            }
            .background(SimpleCareColors.warmBackground)
            .navigationTitle(appointment.title.isEmpty ? appointment.doctorName : appointment.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(SimpleCareColors.calmBlue)
                }
            }
            .alert("Remove Appointment", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    deleteAppointment()
                }
            } message: {
                Text("This will remove this appointment. This cannot be undone.")
            }
        }
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(SimpleCareColors.calmBlue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(SimpleCareColors.secondaryText)
                Text(value)
                    .font(.body)
                    .foregroundStyle(SimpleCareColors.charcoal)
            }
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: appointment.dateTime)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: appointment.dateTime)
    }

    private var prepReminderText: String {
        let minutes = appointment.prepReminderMinutes
        if minutes >= 1440 { return "1 day before" }
        if minutes >= 60 { return "\(minutes / 60) hour\(minutes >= 120 ? "s" : "") before" }
        return "\(minutes) minutes before"
    }

    private func markCompleted() {
        appointment.isCompleted = true
        try? modelContext.save()
        CalmHaptics.gentle()
        dismiss()
    }

    private func deleteAppointment() {
        modelContext.delete(appointment)
        try? modelContext.save()
        NotificationService.shared.cancelAppointmentReminder(for: appointment)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Appointment.self, configurations: config)
    let apt = Appointment(title: "Annual Checkup", doctorName: "Dr. Smith", dateTime: Date(), location: "123 Main St")
    container.mainContext.insert(apt)

    return AppointmentDetailView(appointment: apt)
        .modelContainer(container)
}
