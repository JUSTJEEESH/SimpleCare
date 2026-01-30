import SwiftUI
import SwiftData

struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var content = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $content)
                    .font(.body)
                    .foregroundStyle(SimpleCareColors.charcoal)
                    .focused($isFocused)
                    .padding(16)
                    .frame(maxHeight: .infinity)
                    .scrollContentBackground(.hidden)
                    .background(SimpleCareColors.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        Group {
                            if content.isEmpty {
                                Text("How are you feeling today?")
                                    .font(.body)
                                    .foregroundStyle(SimpleCareColors.secondaryText.opacity(0.6))
                                    .padding(20)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    .allowsHitTesting(false)
                            }
                        }
                    )
                    .padding(.horizontal, 20)

                Text("You can also use voice dictation by tapping the microphone on your keyboard.")
                    .font(.caption)
                    .foregroundStyle(SimpleCareColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button("Save Note") {
                    saveNote()
                }
                .buttonStyle(PrimaryButtonStyle(backgroundColor: SimpleCareColors.sage))
                .padding(.horizontal, 20)
                .opacity(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer().frame(height: 16)
            }
            .padding(.top, 8)
            .background(SimpleCareColors.warmBackground)
            .navigationTitle("New Note")
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
                isFocused = true
            }
        }
    }

    private func saveNote() {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let note = HealthNote(content: trimmed)
        modelContext.insert(note)
        try? modelContext.save()

        CalmHaptics.gentle()
        dismiss()
    }
}

#Preview {
    AddNoteView()
        .modelContainer(for: HealthNote.self, inMemory: true)
}
