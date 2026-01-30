import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct SimpleCareEntry: TimelineEntry {
    let date: Date
    let userName: String
    let nextMedName: String
    let nextMedDosage: String
    let nextMedTime: Date?
    let takenCount: Int
    let totalCount: Int
}

// MARK: - Provider

struct SimpleCareProvider: TimelineProvider {
    private let suiteName = "group.com.simplecare.shared"

    func placeholder(in context: Context) -> SimpleCareEntry {
        SimpleCareEntry(
            date: .now,
            userName: "Friend",
            nextMedName: "Medication",
            nextMedDosage: "1 tablet",
            nextMedTime: .now,
            takenCount: 2,
            totalCount: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleCareEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleCareEntry>) -> Void) {
        let entry = readEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func readEntry() -> SimpleCareEntry {
        let defaults = UserDefaults(suiteName: suiteName)
        return SimpleCareEntry(
            date: .now,
            userName: defaults?.string(forKey: "widgetUserName") ?? "",
            nextMedName: defaults?.string(forKey: "widgetNextMedName") ?? "",
            nextMedDosage: defaults?.string(forKey: "widgetNextMedDosage") ?? "",
            nextMedTime: defaults?.object(forKey: "widgetNextMedTime") as? Date,
            takenCount: defaults?.integer(forKey: "widgetTakenCount") ?? 0,
            totalCount: defaults?.integer(forKey: "widgetTotalCount") ?? 0
        )
    }
}

// MARK: - Widget Colors

private enum WidgetColors {
    static let calmBlue = Color(red: 0.45, green: 0.62, blue: 0.78)
    static let sage = Color(red: 0.56, green: 0.68, blue: 0.58)
    static let taken = Color(red: 0.45, green: 0.72, blue: 0.52)
}

// MARK: - Widget Views

struct SimpleCareWidgetEntryView: View {
    var entry: SimpleCareEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    // MARK: Small Widget

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(WidgetColors.calmBlue)
                    .font(.caption)
                Text("Simple Care")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !entry.nextMedName.isEmpty {
                Text(entry.nextMedName)
                    .font(.headline)
                    .lineLimit(2)

                if !entry.nextMedDosage.isEmpty {
                    Text(entry.nextMedDosage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let time = entry.nextMedTime {
                    Text(time, style: .time)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(WidgetColors.calmBlue)
                }
            } else if entry.totalCount > 0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(WidgetColors.taken)
                Text("All done!")
                    .font(.headline)
                Text("\(entry.takenCount)/\(entry.totalCount) taken")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("No medications\nscheduled")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: Medium Widget

    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundStyle(WidgetColors.calmBlue)
                        .font(.caption)
                    Text("Simple Care")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !entry.nextMedName.isEmpty {
                    Text("Next Up")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(entry.nextMedName)
                        .font(.headline)
                        .lineLimit(1)
                    if !entry.nextMedDosage.isEmpty {
                        Text(entry.nextMedDosage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let time = entry.nextMedTime {
                        Text(time, style: .time)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(WidgetColors.calmBlue)
                    }
                } else {
                    Text("All done for today!")
                        .font(.headline)
                    Text("Great job keeping on track.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if entry.totalCount > 0 {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 6)
                            .opacity(0.15)
                        Circle()
                            .trim(from: 0, to: CGFloat(entry.takenCount) / CGFloat(max(entry.totalCount, 1)))
                            .stroke(WidgetColors.taken, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text("\(entry.takenCount)/\(entry.totalCount)")
                            .font(.caption.weight(.bold))
                    )

                    Text("Taken")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Configuration

struct SimpleCareWidget: Widget {
    let kind = "SimpleCareWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SimpleCareProvider()) { entry in
            SimpleCareWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Simple Care")
        .description("See your next medication at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct SimpleCareWidgetBundle: WidgetBundle {
    var body: some Widget {
        SimpleCareWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    SimpleCareWidget()
} timeline: {
    SimpleCareEntry(date: .now, userName: "Josh", nextMedName: "Lisinopril", nextMedDosage: "10mg tablet", nextMedTime: .now, takenCount: 2, totalCount: 5)
    SimpleCareEntry(date: .now, userName: "Josh", nextMedName: "", nextMedDosage: "", nextMedTime: nil, takenCount: 5, totalCount: 5)
}

#Preview("Medium", as: .systemMedium) {
    SimpleCareWidget()
} timeline: {
    SimpleCareEntry(date: .now, userName: "Josh", nextMedName: "Lisinopril", nextMedDosage: "10mg tablet", nextMedTime: .now, takenCount: 2, totalCount: 5)
}
