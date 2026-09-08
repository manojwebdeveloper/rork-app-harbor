import Foundation

/// Mirrors `HarborPrivateFamilyLocation/Services/WidgetSnapshotWriter.swift`
/// field-for-field. The widget process has no Firebase listener of its own —
/// the app target writes this into the shared App Group container whenever
/// the Map tab's member list changes, and this target reads it back.
nonisolated struct WidgetSnapshot: Codable {
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

    private static let suiteName = "group.com.appamore.harbor"
    private static let key = "widgetSnapshot"

    static func readLatest() -> WidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func widgetMember(_ member: Member) -> WidgetMember {
        WidgetMember(
            id: member.id,
            name: member.name,
            initials: member.initials,
            tint: WidgetPalette.tint(named: member.tint),
            presence: WidgetPresence(rawValue: member.presence) ?? .stopped,
            status: member.status,
            detail: member.detail,
            place: member.place,
            isOffline: member.isOffline
        )
    }
}
