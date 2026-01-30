import SwiftUI
import SwiftData

struct AppointmentListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Appointment.dateTime)
    private var allAppointments: [Appointment]

    @State private var showAddAppointment = false
    @State private var selectedAppointment: Appointment?

    private var upcomingAppointments: [Appointment] {
        allAppointments.filter { !$0.isCompleted && $0.dateTime >= Calendar.current.startOfDay(for: Date()) }
    }

    private var pastAppointments: [Appointment] {
        allAppointments.filter { $0.isCompleted || $0.dateTime < Calendar.current.startOfDay(for: Date()) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allAppointments.isEmpty {
                    emptyState
                } else {
                    appointmentList
                }
            }
            .background(SimpleCareColors.warmBackground)
            .navigationTitle("Appointments")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddAppointment = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(SimpleCareColors.calmBlue)
                    }
                    .accessibilityLabel("Add appointment")
                }
            }
            .sheet(isPresented: $showAddAppointment) {
                AddAppointmentView()
            }
            .sheet(item: $selectedAppointment) { appointment in
                AppointmentDetailView(appointment: appointment)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(SimpleCareColors.calmBlue.opacity(0.5))

            Text("No appointments yet")
                .font(.title3.weight(.medium))
                .foregroundStyle(SimpleCareColors.charcoal)

            Text("Add your first appointment to keep track.")
                .font(.body)
                .foregroundStyle(SimpleCareColors.secondaryText)
                .multilineTextAlignment(.center)

            Button("Add Appointment") {
                showAddAppointment = true
            }
            .buttonStyle(PrimaryButtonStyle(backgroundColor: SimpleCareColors.calmBlue))
            .padding(.horizontal, 48)
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var appointmentList: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !upcomingAppointments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming")
                            .font(.headline)
                            .foregroundStyle(SimpleCareColors.charcoal)
                            .padding(.horizontal, 20)

                        LazyVStack(spacing: 10) {
                            ForEach(upcomingAppointments, id: \.id) { appointment in
                                AppointmentRowView(appointment: appointment)
                                    .onTapGesture {
                                        CalmHaptics.selection()
                                        selectedAppointment = appointment
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                if !pastAppointments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Past")
                            .font(.headline)
                            .foregroundStyle(SimpleCareColors.secondaryText)
                            .padding(.horizontal, 20)

                        LazyVStack(spacing: 10) {
                            ForEach(pastAppointments.prefix(10), id: \.id) { appointment in
                                AppointmentRowView(appointment: appointment, isPast: true)
                                    .onTapGesture {
                                        CalmHaptics.selection()
                                        selectedAppointment = appointment
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                Spacer(minLength: 32)
            }
            .padding(.top, 12)
        }
    }
}

// MARK: - Appointment Row

struct AppointmentRowView: View {
    let appointment: Appointment
    var isPast: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            // Date badge
            VStack(spacing: 2) {
                Text(dayString)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isPast ? SimpleCareColors.secondaryText : SimpleCareColors.calmBlue)
                    .textCase(.uppercase)
                Text(dateNumber)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(isPast ? SimpleCareColors.secondaryText : SimpleCareColors.charcoal)
            }
            .frame(width: 48, height: 48)
            .background(isPast ? SimpleCareColors.upcoming.opacity(0.1) : SimpleCareColors.calmBlueLight)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.title.isEmpty ? appointment.doctorName : appointment.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isPast ? SimpleCareColors.secondaryText : SimpleCareColors.charcoal)

                if !appointment.doctorName.isEmpty && !appointment.title.isEmpty {
                    Text(appointment.doctorName)
                        .font(.subheadline)
                        .foregroundStyle(SimpleCareColors.secondaryText)
                }

                Text(timeString)
                    .font(.subheadline)
                    .foregroundStyle(isPast ? SimpleCareColors.secondaryText : SimpleCareColors.calmBlue)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SimpleCareColors.secondaryText.opacity(0.5))
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .opacity(isPast ? 0.7 : 1.0)
        .accessibilityElement(children: .combine)
    }

    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: appointment.dateTime)
    }

    private var dateNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: appointment.dateTime)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: appointment.dateTime)
    }
}

#Preview {
    AppointmentListView()
        .modelContainer(for: Appointment.self, inMemory: true)
}
