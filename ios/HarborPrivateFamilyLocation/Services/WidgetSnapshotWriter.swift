import Foundation
import WidgetKit

/// Protocol-first per harbor-ios-standards.
protocol WidgetSnapshotWriting: AnyObject {
    func writeSnapshot(circleName: String, members: [SampleMember])
}

/// Widgets run in their own process with no Firebase listener of their own,
/// so the app writes a small JSON snapshot into the shared App Group
/// container every time the Map tab's member list changes, and asks
/// WidgetKit to reload. The widget target defines its own copy of the
/// snapshot shape (see HarborWidget/WidgetSnapshot.swift) rather than
/// sharing this file, matching how it already duplicates the color palette.
final class WidgetSnapshotWriter: WidgetSnapshotWriting {
    private static let suiteName = "group.com.appamore.harbor"
    private static let key = "widgetSnapshot"

    func writeSnapshot(circleName: String, members: [SampleMember]) {
        guard let defaults = UserDefaults(suiteName: Self.suiteName) else { return }

        let payload = SnapshotPayload(
            circleName: circleName,
            updatedAt: Date(),
            members: members.map { member in
                SnapshotPayload.Member(
                    id: member.id,
                    name: member.name,
                    initials: member.initials,
                    tint: member.tint.rawValue,
                    presence: member.presence.rawValue,
                    status: statusText(for: member),
                    detail: member.lastUpdate,
                    place: member.place,
                    isOffline: member.presence == .stopped
                )
            }
        )

        guard let data = try? JSONEncoder().encode(payload) else { return }
        defaults.set(data, forKey: Self.key)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func statusText(for member: SampleMember) -> String {
        if member.isDriving { return "Driving" }
        return member.place
    }
}

/// Mirrors `HarborWidget/WidgetSnapshot.swift` field-for-field.
private struct SnapshotPayload: Codable {
    struct Member: Codable {
        let id: String
        let name: String
        let initials: String
        let tint: String
        let presence: String
        let status: String
        let detail: String
        let place: String
        let isOffline: Bool
    }

    let circleName: String
    let updatedAt: Date
    let members: [Member]
}
