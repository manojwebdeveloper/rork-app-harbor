import SwiftUI
import WidgetKit

nonisolated struct HarborEntry: TimelineEntry {
    let date: Date
    let member: WidgetMember
    let circle: [WidgetMember]
    let circleName: String

    static let sample = HarborEntry(
        date: .now,
        member: WidgetSample.emily,
        circle: WidgetSample.circle,
        circleName: WidgetSample.circleName
    )

    /// The app has no "pin a person" setting, so the small widget's single
    /// member is just the first one in the circle — a reasonable default,
    /// not a deliberate choice of who matters most.
    static func from(_ snapshot: WidgetSnapshot) -> HarborEntry? {
        guard !snapshot.members.isEmpty else { return nil }
        let members = snapshot.members.map(snapshot.widgetMember)
        return HarborEntry(date: snapshot.updatedAt, member: members[0], circle: members, circleName: snapshot.circleName)
    }
}

nonisolated struct HarborProvider: TimelineProvider {
    func placeholder(in context: Context) -> HarborEntry {
        HarborEntry.sample
    }

    func getSnapshot(in context: Context, completion: @escaping (HarborEntry) -> Void) {
        completion(WidgetSnapshot.readLatest().flatMap(HarborEntry.from) ?? HarborEntry.sample)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HarborEntry>) -> Void) {
        let entry = WidgetSnapshot.readLatest().flatMap(HarborEntry.from) ?? HarborEntry.sample
        // The app reloads timelines itself whenever it writes a fresher
        // snapshot (see WidgetSnapshotWriter), so this entry doesn't need to
        // expire on its own — .never, not a fixed refresh interval.
        completion(Timeline(entries: [entry], policy: .never))
    }
}

/// Home Screen widget: one member (small) or the whole circle (medium).
struct HarborWidget: Widget {
    let kind: String = "HarborWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HarborProvider()) { entry in
            HarborWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Harbor")
        .description("See where your circle is at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HarborWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: HarborEntry

    var body: some View {
        switch family {
        case .systemMedium:
            CircleWidgetView(entry: entry)
        default:
            MemberWidgetView(member: entry.member)
        }
    }
}

/// Small family — a single member's status.
struct MemberWidgetView: View {
    let member: WidgetMember

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Circle()
                    .fill(member.tint.opacity(member.isOffline ? 0.22 : 0.16))
                    .frame(width: 38, height: 38)
                    .overlay { Circle().stroke(member.tint, lineWidth: 2) }
                    .overlay {
                        Text(member.initials)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(member.tint)
                    }

                Spacer()

                Circle()
                    .fill(member.isOffline ? WidgetPalette.slate.opacity(0.5) : member.presence.color)
                    .frame(width: 9, height: 9)
                    .padding(.top, 6)
            }

            Spacer()

            Text(member.name)
                .font(.system(size: 17, weight: .bold))

            Text(member.status)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(member.isOffline ? Color.secondary : Color.primary)

            Text(member.detail)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.top, 1)
        }
    }
}

/// Medium family — up to four members of one circle.
struct CircleWidgetView: View {
    let entry: HarborEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(entry.circleName)
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text(entry.date, style: .time)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 0) {
                ForEach(entry.circle.prefix(4)) { member in
                    VStack(spacing: 5) {
                        Circle()
                            .fill(member.tint.opacity(0.16))
                            .frame(width: 40, height: 40)
                            .overlay { Circle().stroke(member.tint, lineWidth: 2) }
                            .overlay {
                                Text(member.initials)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(member.tint)
                            }
                            .overlay(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(member.presence.color)
                                    .frame(width: 12, height: 12)
                                    .overlay { Circle().stroke(.background, lineWidth: 2) }
                                    .offset(x: 2, y: 2)
                            }

                        Text(member.name)
                            .font(.system(size: 12, weight: .bold))

                        Text(member.place)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Spacer()
        }
    }
}
