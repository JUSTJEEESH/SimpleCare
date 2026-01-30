import SwiftUI
@preconcurrency import SwiftData

struct CircleOfCareView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CareCircleMember.createdAt)
    private var members: [CareCircleMember]

    @Query(filter: #Predicate<Medication> { $0.isActive }, sort: \Medication.name)
    private var medications: [Medication]

    @State private var showAddMember = false
    @State private var showShareSummary = false
    @State private var memberToDelete: CareCircleMember?
    @State private var showDeleteConfirmation = false

    @AppStorage("caregiverMode") private var caregiverMode = false
    @AppStorage("caregiverName") private var caregiverName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if members.isEmpty {
                        emptyState
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                    } else {
                        // Caregiver setup badge
                        if caregiverMode && !caregiverName.isEmpty {
                            caregiverBadge
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                        }

                        // Members list
                        membersSection
                            .padding(.horizontal, 20)
                            .padding(.top, caregiverMode ? 0 : 12)

                        // Share summary
                        shareSummaryCard
                            .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 32)
                }
            }
            .background(SimpleCareColors.warmBackground)
            .navigationTitle("Circle of Care")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(SimpleCareColors.calmBlue)
                }
            }
            .sheet(isPresented: $showAddMember) {
                AddCaregiverView()
            }
            .sheet(isPresented: $showShareSummary) {
                if let summary = buildMedicationSummary() {
                    ShareSheet(items: [summary])
                }
            }
            .alert("Remove from Circle", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    memberToDelete = nil
                }
                Button("Remove", role: .destructive) {
                    if let member = memberToDelete {
                        deleteMember(member)
                    }
                }
            } message: {
                if let member = memberToDelete {
                    Text("Remove \(member.name) from your Circle of Care?")
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)

            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(SimpleCareColors.calmBlue.opacity(0.7))

            VStack(spacing: 12) {
                Text("Your Circle of Care")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(SimpleCareColors.charcoal)

                Text("Add the people who care about you. They can help keep track of your medications and be there when you need them.")
                    .font(.body)
                    .foregroundStyle(SimpleCareColors.charcoalLight)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
            }

            // What they can do
            VStack(alignment: .leading, spacing: 14) {
                benefitRow(
                    icon: "phone.fill",
                    text: "Quick call or message — one tap away"
                )
                benefitRow(
                    icon: "bell.fill",
                    text: "Get notified if an important dose is missed"
                )
                benefitRow(
                    icon: "doc.text.fill",
                    text: "Share your medication summary anytime"
                )
            }
            .padding(20)
            .background(SimpleCareColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)

            Button {
                showAddMember = true
                CalmHaptics.selection()
            } label: {
                Label("Add Someone to Your Circle", systemImage: "person.badge.plus")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56)
            }
            .buttonStyle(PrimaryButtonStyle(backgroundColor: SimpleCareColors.calmBlue))
            .padding(.horizontal, 12)

            Spacer()
        }
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(SimpleCareColors.calmBlue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(SimpleCareColors.charcoal)
                .lineSpacing(2)
        }
    }

    // MARK: - Caregiver Badge

    private var caregiverBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "heart.circle.fill")
                .font(.title3)
                .foregroundStyle(SimpleCareColors.heartRed)
            VStack(alignment: .leading, spacing: 2) {
                Text("Set up by \(caregiverName)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SimpleCareColors.charcoal)
                Text("Caring from a distance")
                    .font(.caption)
                    .foregroundStyle(SimpleCareColors.secondaryText)
            }
            Spacer()
        }
        .padding(14)
        .background(SimpleCareColors.heartRedLight)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Members Section

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your Circle")
                    .font(.headline)
                    .foregroundStyle(SimpleCareColors.charcoal)
                Spacer()
                Button {
                    showAddMember = true
                    CalmHaptics.selection()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(SimpleCareColors.calmBlue)
                }
                .accessibilityLabel("Add person")
            }

            ForEach(members, id: \.id) { member in
                memberCard(member)
            }
        }
        .gentleCard()
    }

    private func memberCard(_ member: CareCircleMember) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Initials avatar
                initialsAvatar(for: member)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(member.name)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(SimpleCareColors.charcoal)
                        if member.isEmergencyContact {
                            Text("Emergency")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(SimpleCareColors.heartRed)
                                .clipShape(Capsule())
                        }
                    }
                    Text(member.relationship)
                        .font(.subheadline)
                        .foregroundStyle(SimpleCareColors.secondaryText)
                }

                Spacer()

                // Quick actions
                if !member.phoneNumber.isEmpty {
                    HStack(spacing: 8) {
                        quickContactButton(
                            icon: "phone.fill",
                            color: SimpleCareColors.taken,
                            accessibilityLabel: "Call \(member.name)"
                        ) {
                            callMember(member)
                        }

                        quickContactButton(
                            icon: "message.fill",
                            color: SimpleCareColors.calmBlue,
                            accessibilityLabel: "Message \(member.name)"
                        ) {
                            messageMember(member)
                        }
                    }
                }
            }

            // Info row
            HStack(spacing: 16) {
                if !member.phoneNumber.isEmpty {
                    Label(member.phoneNumber, systemImage: "phone")
                        .font(.caption)
                        .foregroundStyle(SimpleCareColors.secondaryText)
                }
                Spacer()
                if member.notifyOnMissedDose {
                    Label("Missed dose alerts", systemImage: "bell.fill")
                        .font(.caption)
                        .foregroundStyle(SimpleCareColors.sage)
                }
            }

            // Remove button
            HStack {
                Spacer()
                Button {
                    memberToDelete = member
                    showDeleteConfirmation = true
                } label: {
                    Text("Remove")
                        .font(.caption)
                        .foregroundStyle(SimpleCareColors.destructive.opacity(0.7))
                }
            }
        }
        .padding(14)
        .background(SimpleCareColors.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func initialsAvatar(for member: CareCircleMember) -> some View {
        let initials = member.name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .uppercased()

        return Text(initials.isEmpty ? "?" : initials)
            .font(.body.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(SimpleCareColors.calmBlue)
            .clipShape(Circle())
    }

    private func quickContactButton(
        icon: String,
        color: Color,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
            CalmHaptics.selection()
        } label: {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.12))
                .clipShape(Circle())
        }
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Share Summary Card

    private var shareSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share")
                .font(.headline)
                .foregroundStyle(SimpleCareColors.charcoal)

            Text("Send your medication list and schedule to your care circle.")
                .font(.subheadline)
                .foregroundStyle(SimpleCareColors.secondaryText)
                .lineSpacing(3)

            Button {
                showShareSummary = true
                CalmHaptics.gentle()
            } label: {
                Label("Share Medication Summary", systemImage: "square.and.arrow.up")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
            }
            .buttonStyle(PrimaryButtonStyle(backgroundColor: SimpleCareColors.sage))
        }
        .gentleCard()
    }

    // MARK: - Helpers

    private func callMember(_ member: CareCircleMember) {
        let cleaned = member.phoneNumber.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    private func messageMember(_ member: CareCircleMember) {
        let cleaned = member.phoneNumber.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "sms:\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    private func deleteMember(_ member: CareCircleMember) {
        modelContext.delete(member)
        try? modelContext.save()
        memberToDelete = nil
        CalmHaptics.selection()
    }

    private func buildMedicationSummary() -> String? {
        guard !medications.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.timeStyle = .short

        var lines: [String] = []
        lines.append("Medication Summary")
        lines.append("from Simple Care")
        lines.append("")

        for med in medications {
            lines.append("- \(med.name)")
            if !med.dosage.isEmpty {
                lines.append("  Dosage: \(med.dosage)")
            }
            let times = med.scheduleTimes.map { formatter.string(from: $0) }.joined(separator: ", ")
            if !times.isEmpty {
                lines.append("  Schedule: \(times)")
            }
            if med.isCritical {
                lines.append("  ** Important medication")
            }
            if !med.notes.isEmpty {
                lines.append("  Notes: \(med.notes)")
            }
            lines.append("")
        }

        lines.append("Shared from Simple Care app")
        return lines.joined(separator: "\n")
    }
}

#Preview {
    CircleOfCareView()
        .modelContainer(for: [CareCircleMember.self, Medication.self, MedicationLog.self], inMemory: true)
}
