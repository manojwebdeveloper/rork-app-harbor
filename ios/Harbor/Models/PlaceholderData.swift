import SwiftUI

/// Static, hard-coded data used to populate the Phase 2 layout screens.
///
/// Nothing in this file is persisted, synced or read from a backend. It exists so the
/// Phase 2 screens can be reviewed with realistic content before the location engine,
/// rule evaluation and digest services are built.
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
    /// Position on the stylised map canvas, in unit coordinates.
    let mapPoint: CGPoint

    var isBatteryLow: Bool {
        guard let batteryPercent else { return false }
        return batteryPercent <= 20
    }
}

struct SampleCircle: Identifiable, Hashable {
    let id: String
    let name: String
    let tint: SampleTint
    let memberCount: Int
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

struct SampleSmartAlertRule: Identifiable, Hashable {
    let id: String
    let person: String
    let event: String
    let comparator: String
    let time: String
    let frequency: String
    let days: [Int]
    let isOn: Bool

    var sentence: String {
        "Notify me if \(person) \(event) \(comparator) \(time)"
    }
}

struct SampleMemberDigest: Identifiable, Hashable {
    let id: String
    let name: String
    let initials: String
    let tint: SampleTint
    let summary: String
    let checkIns: Int
    let places: Int
    let alerts: Int
    let placeNames: [String]
}

enum HarborSample {
    static let members: [SampleMember] = [
        SampleMember(
            id: "maya",
            name: "Maya",
            initials: "M",
            tint: .sky,
            presence: .upToDate,
            place: "Home",
            statusDetail: "Updated now",
            batteryPercent: 82,
            speedText: nil,
            isDriving: false,
            address: "24 Willow Road",
            lastUpdate: "Just now",
            accuracy: "Within 12 m",
            sharing: "On · always",
            mapPoint: CGPoint(x: 0.26, y: 0.26)
        ),
        SampleMember(
            id: "james",
            name: "James",
            initials: "J",
            tint: .teal,
            presence: .upToDate,
            place: "Live now",
            statusDetail: "Live now",
            batteryPercent: 54,
            speedText: "42 mph",
            isDriving: true,
            address: "A329 towards Reading",
            lastUpdate: "Live now",
            accuracy: "Within 30 m",
            sharing: "On · always",
            mapPoint: CGPoint(x: 0.62, y: 0.44)
        ),
        SampleMember(
            id: "emily",
            name: "Emily",
            initials: "E",
            tint: .coral,
            presence: .needsAttention,
            place: "School",
            statusDetail: "School · Updated 4 min ago",
            batteryPercent: 14,
            speedText: nil,
            isDriving: false,
            address: "Lakeside Primary School",
            lastUpdate: "4 min ago",
            accuracy: "Within 25 m",
            sharing: "On · always",
            mapPoint: CGPoint(x: 0.74, y: 0.62)
        )
    ]

    static let you = SampleMember(
        id: "you",
        name: "You",
        initials: "A",
        tint: .amber,
        presence: .upToDate,
        place: "Home",
        statusDetail: "Updated now",
        batteryPercent: 88,
        speedText: nil,
        isDriving: false,
        address: "24 Willow Road",
        lastUpdate: "Just now",
        accuracy: "Within 10 m",
        sharing: "On · always",
        mapPoint: CGPoint(x: 0.3, y: 0.7)
    )

    static let tripMembers: [SampleMember] = [
        SampleMember(
            id: "james-trip",
            name: "James",
            initials: "J",
            tint: .teal,
            presence: .upToDate,
            place: "Hotel",
            statusDetail: "Updated 6 min ago",
            batteryPercent: 61,
            speedText: nil,
            isDriving: false,
            address: "Hôtel Saint-Germain",
            lastUpdate: "6 min ago",
            accuracy: "Within 20 m",
            sharing: "On · until the trip ends",
            mapPoint: CGPoint(x: 0.26, y: 0.26)
        ),
        SampleMember(
            id: "emily-trip",
            name: "Emily",
            initials: "E",
            tint: .coral,
            presence: .upToDate,
            place: "Louvre",
            statusDetail: "Updated 2 min ago",
            batteryPercent: 73,
            speedText: nil,
            isDriving: false,
            address: "Musée du Louvre",
            lastUpdate: "2 min ago",
            accuracy: "Within 18 m",
            sharing: "On · until the trip ends",
            mapPoint: CGPoint(x: 0.62, y: 0.44)
        )
    ]

    static let circles: [SampleCircle] = [
        SampleCircle(
            id: "harris",
            name: "The Harris Family",
            tint: .teal,
            memberCount: 4,
            isTrip: false,
            durationText: "permanent",
            memberInitials: ["M", "J", "E", "A"],
            memberTints: [.sky, .teal, .coral, .amber]
        ),
        SampleCircle(
            id: "friends",
            name: "Friends",
            tint: .coral,
            memberCount: 3,
            isTrip: false,
            durationText: "permanent",
            memberInitials: ["M", "E", "A"],
            memberTints: [.sky, .coral, .amber]
        ),
        SampleCircle(
            id: "paris",
            name: "Paris Trip",
            tint: .sky,
            memberCount: 3,
            isTrip: true,
            durationText: "Ends tomorrow, 8:00 PM",
            memberInitials: ["J", "E", "A"],
            memberTints: [.teal, .coral, .amber]
        )
    ]

    static let activityToday: [SampleActivityEntry] = [
        SampleActivityEntry(
            id: "arrived",
            time: "09:42",
            title: "Maya arrived at School",
            detail: "2 minutes ago",
            tint: .teal,
            badge: nil
        ),
        SampleActivityEntry(
            id: "checkin",
            time: "08:15",
            title: "James checked in",
            detail: "“Reached the office safely”",
            tint: .teal,
            badge: nil
        ),
        SampleActivityEntry(
            id: "left",
            time: "07:58",
            title: "Emily left Home",
            detail: "Battery 71%",
            tint: .sky,
            badge: nil
        )
    ]

    static let activityAsCircleSeesIt: [SampleActivityEntry] = [
        SampleActivityEntry(
            id: "safe",
            time: "Now",
            title: "Alex is safe",
            detail: "Sent from the map · no location shared",
            tint: .teal,
            badge: "SAFE"
        ),
        SampleActivityEntry(
            id: "driving",
            time: "16:12",
            title: "James started driving",
            detail: "Leaving the office",
            tint: .sky,
            badge: nil
        ),
        SampleActivityEntry(
            id: "battery",
            time: "15:40",
            title: "Emily’s battery is low",
            detail: "14% remaining",
            tint: .amber,
            badge: nil
        )
    ]

    static let smartAlertRules: [SampleSmartAlertRule] = [
        SampleSmartAlertRule(
            id: "emily-evening",
            person: "Emily",
            event: "arrives",
            comparator: "after",
            time: "6:00 PM",
            frequency: "Every time",
            days: [1, 2, 3, 4, 5],
            isOn: true
        ),
        SampleSmartAlertRule(
            id: "everyone-home",
            person: "Not everyone",
            event: "is home",
            comparator: "by",
            time: "10:00 PM",
            frequency: "Once a day",
            days: [0, 1, 2, 3, 4, 5, 6],
            isOn: true
        )
    ]

    static let ruleExamples: [String] = [
        "Notify me if Emily arrives after 6:00 PM",
        "Alert me if not everyone is home by 10:00 PM",
        "Notify me if James is still here after 8:00 PM"
    ]

    static let digestMembers: [SampleMemberDigest] = [
        SampleMemberDigest(
            id: "maya",
            name: "Maya",
            initials: "M",
            tint: .sky,
            summary: "A steady week",
            checkIns: 5,
            places: 3,
            alerts: 0,
            placeNames: ["Home", "Work", "School"]
        ),
        SampleMemberDigest(
            id: "james",
            name: "James",
            initials: "J",
            tint: .teal,
            summary: "Most on the move",
            checkIns: 6,
            places: 4,
            alerts: 1,
            placeNames: ["Home", "Work", "Gym", "Airport"]
        ),
        SampleMemberDigest(
            id: "emily",
            name: "Emily",
            initials: "E",
            tint: .coral,
            summary: "School and back, every day",
            checkIns: 3,
            places: 2,
            alerts: 0,
            placeNames: ["Home", "School"]
        ),
        SampleMemberDigest(
            id: "you",
            name: "You",
            initials: "A",
            tint: .amber,
            summary: "Quietest week of the four",
            checkIns: 0,
            places: 2,
            alerts: 0,
            placeNames: ["Home", "Work"]
        )
    ]

    static let digestRange = "31 Aug – 6 Sep"
    static let digestCircleName = "The Harris Family"
    static let digestCheckIns = 14
    static let digestPlaces = 6
    static let digestAlerts = 1
}
