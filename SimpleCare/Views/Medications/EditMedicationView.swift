import SwiftUI
import SwiftData
import PhotosUI

struct EditMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var medication: Medication

    @State private var name: String
    @State private var dosage: String
    @State private var notes: String
    @State private var scheduleTimes: [Date]
    @State private var isCritical: Bool
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?

    init(medication: Medication) {
        self.medication = medication
        _name = State(initialValue: medication.name)
        _dosage = State(initialValue: medication.dosage)
        _notes = State(initialValue: medication.notes)
        _scheduleTimes = State(initialValue: medication.scheduleTimes)
        _isCritical = State(initialValue: medication.isCritical)
        _photoData = State(initialValue: medication.photoData)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo
                    photoSection
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    // Name
                    fieldSection(title: "Medication Name") {
                        TextField("Medication name", text: $name)
                            .font(.body)
                            .foregroundStyle(SimpleCareColors.charcoal)
                            .padding(14)
                            .background(SimpleCareColors.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(SimpleCareColors.sage.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)

                    // Dosage
                    fieldSection(title: "Dosage") {
                        TextField("e.g., 1 tablet, 10mg", text: $dosage)
                            .font(.body)
                            .foregroundStyle(SimpleCareColors.charcoal)
                            .padding(14)
                            .background(SimpleCareColors.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(SimpleCareColors.sage.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)

                    // Schedule
                    scheduleSection
                        .padding(.horizontal, 20)

                    // Important
                    importantSection
                        .padding(.horizontal, 20)

                    // Notes
                    fieldSection(title: "Notes") {
                        TextEditor(text: $notes)
                            .font(.body)
                            .foregroundStyle(SimpleCareColors.charcoal)
                            .scrollContentBackground(.hidden)
                            .frame(height: 100)
                            .padding(12)
                            .background(SimpleCareColors.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(SimpleCareColors.sage.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)

                    // Save
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: SimpleCareColors.sage))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .opacity(canSave ? 1.0 : 0.5)
                    .disabled(!canSave)

                    Spacer(minLength: 32)
                }
            }
            .background(SimpleCareColors.warmBackground)
            .navigationTitle("Edit Medication")
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

    // MARK: - Photo

    private var photoSection: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            if let data = photoData, let uiImage = UIImage(data: data) {
                HStack(spacing: 14) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pill Photo")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(SimpleCareColors.charcoal)
                        Text("Tap to change")
                            .font(.caption)
                            .foregroundStyle(SimpleCareColors.calmBlue)
                    }

                    Spacer()

                    Button {
                        photoData = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(SimpleCareColors.secondaryText)
                    }
                }
                .padding(14)
                .background(SimpleCareColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                        .font(.body)
                    Text("Add a photo of this pill")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(SimpleCareColors.calmBlue)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .background(SimpleCareColors.calmBlueLight)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    photoData = processPhoto(data)
                }
            }
        }
    }

    // MARK: - Schedule

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schedule")
                .font(.headline)
                .foregroundStyle(SimpleCareColors.charcoal)

            ForEach(scheduleTimes.indices, id: \.self) { index in
                HStack(spacing: 12) {
                    Text("Time \(index + 1)")
                        .font(.body.weight(.medium))
                        .foregroundStyle(SimpleCareColors.charcoal)

                    Spacer()

                    DatePicker(
                        "",
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
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(SimpleCareColors.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button {
                let newTime = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
                scheduleTimes.append(newTime)
                CalmHaptics.selection()
            } label: {
                Label("Add another time", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SimpleCareColors.calmBlue)
            }
        }
        .gentleCard()
    }

    // MARK: - Important

    private var importantSection: some View {
        Button {
            isCritical.toggle()
            CalmHaptics.selection()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isCritical ? "heart.fill" : "heart")
                    .font(.system(size: 24))
                    .foregroundStyle(isCritical ? SimpleCareColors.heartRed : SimpleCareColors.secondaryText)

                Text("Important medication")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(SimpleCareColors.charcoal)

                Spacer()

                Image(systemName: isCritical ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCritical ? SimpleCareColors.heartRed : SimpleCareColors.upcoming)
            }
        }
        .padding(18)
        .background(isCritical ? SimpleCareColors.heartRedLight : SimpleCareColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isCritical ? SimpleCareColors.heartRed.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        .animation(.easeInOut(duration: 0.2), value: isCritical)
    }

    // MARK: - Helpers

    private func fieldSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(SimpleCareColors.charcoal)
            content()
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !scheduleTimes.isEmpty
    }

    private func processPhoto(_ data: Data) -> Data? {
        guard let uiImage = UIImage(data: data) else { return nil }
        let maxDimension: CGFloat = 400
        let size = uiImage.size
        let scale = min(maxDimension / max(size.width, size.height), 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.6)
    }

    private func saveChanges() {
        medication.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        medication.dosage = dosage.trimmingCharacters(in: .whitespacesAndNewlines)
        medication.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        medication.scheduleTimesData = try? JSONEncoder().encode(scheduleTimes)
        medication.isCritical = isCritical
        medication.photoData = photoData

        try? modelContext.save()

        // Reschedule notifications with new times
        NotificationService.shared.cancelReminders(for: medication)
        NotificationService.shared.scheduleMedicationReminders(for: medication)

        CalmHaptics.gentle()
        dismiss()
    }
}
