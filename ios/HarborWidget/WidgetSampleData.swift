import SwiftUI

/// Sample people for the Harbor widgets' placeholder/redacted preview state
/// (`HarborProvider.placeholder`) and as a fallback before the app has ever
/// written a real snapshot (see `WidgetSnapshot.readLatest()`). Colours are
/// duplicated here because the app's asset catalog belongs to the app target.
nonisolated enum WidgetPalette {
    static let calmTeal = Color(red: 0.03, green: 0.50, blue: 0.47)
    static let clearSky = Color(red: 0.36, green: 0.55, blue: 0.94)
    static let softCoral = Color(red: 0.95, green: 0.46, blue: 0.42)
    static let warmAmber = Color(red: 0.91, green: 0.65, blue: 0.23)
    static let safeGreen = Color(red: 0.20, green: 0.66, blue: 0.45)
    static let slate = Color(red: 0.40, green: 0.45, blue: 0.49)

    /// Matches `SampleTint.rawValue` from the app target ("sky", "teal", "coral", "amber").
    static func tint(named name: String) -> Color {
        switch name {
        case "sky": clearSky
        case "teal": calmTeal
        case "coral": softCoral
        case "amber": warmAmber
        default: slate
        }
    }
}

nonisolated enum WidgetPresence: String {
    case upToDate
    case needsAttention
    case stopped

    var color: Color {
        switch self {
        case .upToDate: WidgetPalette.safeGreen
        case .needsAttention: WidgetPalette.warmAmber
        case .stopped: WidgetPalette.softCoral
        }
    }
}

nonisolated struct WidgetMember: Identifiable, Hashable {
    let id: String
    let name: String
    let initials: String
    let tint: Color
    let presence: WidgetPresence
    /// Headline status, e.g. "At School" or "Phone offline".
    let status: String
    /// Secondary line, e.g. "Updated 4 min ago".
    let detail: String
    /// Short label used under the medium widget avatars.
    let place: String
    let isOffline: Bool

    static func == (lhs: WidgetMember, rhs: WidgetMember) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

nonisolated enum WidgetSample {
    static let circleName = "The Harris Family"

    static let emily = WidgetMember(
        id: "emily",
        name: "Emily",
        initials: "E",
        tint: WidgetPalette.softCoral,
        presence: .upToDate,
        status: "At School",
        detail: "Updated 4 min ago",
        place: "School",
        isOffline: false
    )

    static let james = WidgetMember(
        id: "james",
        name: "James",
        initials: "J",
        tint: WidgetPalette.slate,
        presence: .stopped,
        status: "Phone offline",
        detail: "Last known 3:12 PM",
        place: "Driving",
        isOffline: true
    )

    static let circle: [WidgetMember] = [
        WidgetMember(
            id: "maya",
            name: "Maya",
            initials: "M",
            tint: WidgetPalette.clearSky,
            presence: .upToDate,
            status: "At Home",
            detail: "Updated now",
            place: "Home",
            isOffline: false
        ),
        WidgetMember(
            id: "james",
            name: "James",
            initials: "J",
            tint: WidgetPalette.calmTeal,
            presence: .upToDate,
            status: "Driving",
            detail: "Live now",
            place: "Driving",
            isOffline: false
        ),
        WidgetMember(
            id: "emily",
            name: "Emily",
            initials: "E",
            tint: WidgetPalette.softCoral,
            presence: .needsAttention,
            status: "At School",
            detail: "Updated 4 min ago",
            place: "School",
            isOffline: false
        ),
        WidgetMember(
            id: "you",
            name: "You",
            initials: "A",
            tint: WidgetPalette.warmAmber,
            presence: .upToDate,
            status: "At Home",
            detail: "Updated now",
            place: "Home",
            isOffline: false
        )
    ]
}
