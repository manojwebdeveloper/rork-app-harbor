import CoreLocation
import SwiftUI

/// Presentation-layer types for the Map and Activity tabs. Real data (from
/// `CircleService`, `LiveCircleLocationsService`, `ActivityService`) is
/// mapped into these at the view layer — see `MainMapView`,
/// `CircleSwitcherView` and `ActivityTimelineMapping`. Despite the "Sample"
/// name (kept from when these screens were Phase 2 mockups with hard-coded
/// data), nothing here is sample data itself; these are just display models.
enum SampleTint: String, Hashable, CaseIterable {
    case sky
    case teal
    case coral
    case amber

    var color: Color {
        switch self {
        case .sky: Color(.clearSky)
        case .teal: Color(.calmTeal)
        case .coral: Color(.softCoral)
        case .amber: Color(.warmAmber)
        }
    }
}

/// The three status dots used across the map, widgets and member lists.
enum SamplePresence: String, Hashable {
    case upToDate
    case needsAttention
    case stopped

    var color: Color {
        switch self {
        case .upToDate: Color(.safeGreen)
        case .needsAttention: Color(.warmAmber)
        case .stopped: Color(.softCoral)
        }
    }

    var caption: String {
        switch self {
        case .upToDate: "Sharing and up to date"
        case .needsAttention: "Low battery or slow to update"
        case .stopped: "Sharing stopped — nothing to show"
        }
    }
}

struct SampleMember: Identifiable, Hashable {
    let id: String
    let name: String
    let initials: String
    let tint: SampleTint
    let presence: SamplePresence
    /// Short place label shown on the map strip, e.g. "Home".
    let place: String
    /// Secondary line on the detail sheet, e.g. "Updated 4 min ago".
    let statusDetail: String
    let batteryPercent: Int?
    let speedText: String?
    let isDriving: Bool
    let address: String
    let lastUpdate: String
    let accuracy: String
    let sharing: String
    let coordinate: CLLocationCoordinate2D
    /// Whether this row is the signed-in user's own entry — the map pin and
    /// status strip give it a distinct highlight so it reads as "you" at a
    /// glance, the way Life360/Find My distinguish your own marker.
    var isSelf = false

    var isBatteryLow: Bool {
        guard let batteryPercent else { return false }
        return batteryPercent <= 20
    }

    static func == (lhs: SampleMember, rhs: SampleMember) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct SampleCircle: Identifiable, Hashable {
    let id: String
    let name: String
    let tint: SampleTint
    /// `nil` when the count isn't known yet (real circles other than the
    /// selected one don't fetch member counts on the map switcher — see
    /// MainMapView; `ManageCirclesView` does fetch them).
    let memberCount: Int?
    let isTrip: Bool
    /// e.g. "permanent" or "Ends tomorrow, 8:00 PM".
    let durationText: String
    let memberInitials: [String]
    let memberTints: [SampleTint]
}

struct SampleActivityEntry: Identifiable, Hashable {
    let id: String
    let time: String
    let title: String
    let detail: String
    let tint: SampleTint
    let badge: String?
}
