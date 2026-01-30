import SwiftUI
import SwiftData

struct NoteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let note: HealthNote

    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(formattedDate(note.createdAt))
                        .font(.subheadline)
                        .foregroundStyle(SimpleCareColors.secondaryText)

                    Text(note.content)
                        .font(.body)
                        .foregroundStyle(SimpleCareColors.charcoal)
                        .lineSpacing(6)

                    Spacer(minLength: 32)

                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete Note")
                            .font(.body)
                            .foregroundStyle(SimpleCareColors.destructive)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 50)
                            .background(SimpleCareColors.destructive.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(SimpleCareColors.warmBackground)
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(SimpleCareColors.calmBlue)
                }
            }
            .alert("Delete Note", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteNote()
                }
            } message: {
                Text("This note will be permanently deleted.")
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func deleteNote() {
        modelContext.delete(note)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: HealthNote.self, configurations: config)
    let note = HealthNote(content: "Felt dizzy after breakfast. Better after drinking water.")
    container.mainContext.insert(note)

    return NoteDetailView(note: note)
        .modelContainer(container)
}
