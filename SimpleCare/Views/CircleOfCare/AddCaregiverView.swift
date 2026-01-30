import SwiftUI
import SwiftData

struct AddCaregiverView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var relationship = "Family"
    @State private var phoneNumber = ""
    @State private var isEmergencyContact = false
    @State private var notifyOnMissedDose = true

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name, phone
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Name
                    fieldSection(title: "Name") {
                        TextField("Full name", text: $name)
                            .font(.body)
                            .foregroundStyle(SimpleCareColors.charcoal)
                            .textContentType(.name)
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .phone }
                            .padding(14)
                            .background(SimpleCareColors.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(SimpleCareColors.sage.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Relationship
                    fieldSection(title: "Relationship") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(CareCircleMember.relationships, id: \.self) { rel in
                                    relationshipChip(rel)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Phone
                    fieldSection(title: "Phone Number") {
                        TextField("(555) 123-4567", text: $phoneNumber)
                            .font(.body)
                            .foregroundStyle(SimpleCareColors.charcoal)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                            .focused($focusedField, equals: .phone)
                            .padding(14)
                            .background(SimpleCareColors.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(SimpleCareColors.sage.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)

                    // Emergency contact
                    toggleCard(
                        icon: "staroflife.fill",
                        iconColor: SimpleCareColors.heartRed,
                        title: "Emergency Contact",
                        subtitle: "Show at the top of your care circle",
                        isOn: $isEmergencyContact
                    )
                    .padding(.horizontal, 20)

                    // Missed dose alerts
                    toggleCard(
                        icon: "bell.fill",
                        iconColor: SimpleCareColors.sage,
                        title: "Missed Dose Alerts",
                        subtitle: "Gently notify when an important medication is missed",
                        isOn: $notifyOnMissedDose
                    )
                    .padding(.horizontal, 20)

                    // Save
                    Button("Add to Circle") {
                        saveMember()
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: SimpleCareColors.calmBlue))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .opacity(canSave ? 1.0 : 0.5)
                    .disabled(!canSave)

                    Spacer(minLength: 32)
                }
            }
            .background(SimpleCareColors.warmBackground)
            .navigationTitle("Add to Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(SimpleCareColors.secondaryText)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    focusedField = .name
                }
            }
        }
    }

    // MARK: - Components

    private func fieldSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(SimpleCareColors.charcoal)
            content()
        }
    }

    private func relationshipChip(_ rel: String) -> some View {
        Button {
            relationship = rel
            CalmHaptics.selection()
        } label: {
            Text(rel)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(relationship == rel ? .white : SimpleCareColors.charcoal)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(relationship == rel ? SimpleCareColors.calmBlue : SimpleCareColors.fieldBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(
                            relationship == rel ? Color.clear : SimpleCareColors.sage.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
        .accessibilityAddTraits(relationship == rel ? .isSelected : [])
    }

    private func toggleCard(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        Button {
            isOn.wrappedValue.toggle()
            CalmHaptics.selection()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isOn.wrappedValue ? iconColor : SimpleCareColors.secondaryText)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(SimpleCareColors.charcoal)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(SimpleCareColors.secondaryText)
                        .lineSpacing(2)
                }

                Spacer()

                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isOn.wrappedValue ? iconColor : SimpleCareColors.upcoming)
            }
        }
        .padding(16)
        .background(SimpleCareColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        .animation(.easeInOut(duration: 0.2), value: isOn.wrappedValue)
    }

    // MARK: - Helpers

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveMember() {
        let member = CareCircleMember(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            relationship: relationship,
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            isEmergencyContact: isEmergencyContact,
            notifyOnMissedDose: notifyOnMissedDose
        )
        modelContext.insert(member)
        try? modelContext.save()
        CalmHaptics.gentle()
        dismiss()
    }
}

#Preview {
    AddCaregiverView()
        .modelContainer(for: CareCircleMember.self, inMemory: true)
}
