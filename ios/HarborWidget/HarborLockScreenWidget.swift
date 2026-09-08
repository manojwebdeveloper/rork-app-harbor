import SwiftUI
import WidgetKit

/// Lock Screen accessories: one line of reassurance, never a map or an address.
struct HarborLockScreenWidget: Widget {
    let kind: String = "HarborLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HarborProvider()) { entry in
            HarborLockScreenView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Harbor status")
        .description("A single line — nothing an onlooker could use to find someone.")
        .supportedFamilies([.accessoryInline, .accessoryRectangular, .accessoryCircular])
    }
}

struct HarborLockScreenView: View {
    @Environment(\.widgetFamily) private var family

    let entry: HarborEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Label(lockSummary, systemImage: "mappin.and.ellipse")

        case .accessoryCircular:
            VStack(spacing: 1) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text("\(sharingCount)")
                    .font(.system(size: 15, weight: .bold))
            }

        default:
            VStack(alignment: .leading, spacing: 2) {
                Text("HARBOR")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)

                Text("\(entry.member.name) at \(entry.member.place)")
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)

                Text(entry.member.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var sharingCount: Int {
        entry.circle.filter { !$0.isOffline }.count
    }

    private var lockSummary: String {
        let onlineCount = sharingCount
        guard onlineCount > 0 else { return "No one sharing right now" }
        let allHome = entry.circle.allSatisfy { $0.place == "Home" }
        return allHome ? "Everyone home" : "\(onlineCount) sharing"
    }
}
