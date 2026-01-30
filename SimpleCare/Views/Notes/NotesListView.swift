import SwiftUI
import SwiftData

struct NotesListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \HealthNote.createdAt, order: .reverse)
    private var notes: [HealthNote]

    @State private var showAddNote = false
    @State private var selectedNote: HealthNote?

    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty {
                    emptyState
                } else {
                    notesList
                }
            }
            .background(SimpleCareColors.warmBackground)
            .navigationTitle("Health Notes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddNote = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(SimpleCareColors.calmBlue)
                    }
                    .accessibilityLabel("Add note")
                }
            }
            .sheet(isPresented: $showAddNote) {
                AddNoteView()
            }
            .sheet(item: $selectedNote) { note in
                NoteDetailView(note: note)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundStyle(SimpleCareColors.sage.opacity(0.5))

            Text("No notes yet")
                .font(.title3.weight(.medium))
                .foregroundStyle(SimpleCareColors.charcoal)

            Text("Write down how you're feeling\nor anything you want to remember.")
                .font(.body)
                .foregroundStyle(SimpleCareColors.secondaryText)
                .multilineTextAlignment(.center)

            Button("Add a Note") {
                showAddNote = true
            }
            .buttonStyle(PrimaryButtonStyle(backgroundColor: SimpleCareColors.sage))
            .padding(.horizontal, 48)
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(notes, id: \.id) { note in
                    noteRow(note)
                        .onTapGesture {
                            CalmHaptics.selection()
                            selectedNote = note
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }

    private func noteRow(_ note: HealthNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.content)
                .font(.body)
                .foregroundStyle(SimpleCareColors.charcoal)
                .lineLimit(3)

            Text(formattedDate(note.createdAt))
                .font(.caption)
                .foregroundStyle(SimpleCareColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(SimpleCareColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NotesListView()
        .modelContainer(for: HealthNote.self, inMemory: true)
}
