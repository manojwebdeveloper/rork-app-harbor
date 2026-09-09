import Foundation
import SwiftUI

/// Backed by `users/{uid}.notificationPreferences`. Defaults match what a
/// signed-in user with no preferences document yet should see: alerts and
/// check-ins on, Quiet Hours off.
struct NotificationPreferences: Equatable {
    var arrivalsAndDepartures = true
    var checkIns = true
    var quietHoursEnabled = false
    /// Minutes since local midnight.
    var quietHoursStart = 22 * 60
    var quietHoursEnd = 7 * 60

    init(
        arrivalsAndDepartures: Bool = true,
        checkIns: Bool = true,
        quietHoursEnabled: Bool = false,
        quietHoursStart: Int = 22 * 60,
        quietHoursEnd: Int = 7 * 60
    ) {
        self.arrivalsAndDepartures = arrivalsAndDepartures
        self.checkIns = checkIns
        self.quietHoursEnabled = quietHoursEnabled
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
    }

    init?(document data: [String: Any]?) {
        guard let data else { return nil }
        self.init(
            arrivalsAndDepartures: data["arrivalsAndDepartures"] as? Bool ?? true,
            checkIns: data["checkIns"] as? Bool ?? true,
            quietHoursEnabled: data["quietHoursEnabled"] as? Bool ?? false,
            quietHoursStart: data["quietHoursStart"] as? Int ?? 22 * 60,
            quietHoursEnd: data["quietHoursEnd"] as? Int ?? 7 * 60
        )
    }
}

/// How long a newly-started sharing session lasts before Harbor asks again.
/// Backed by `users/{uid}.sharingExpirationPreference`.
enum SharingExpirationOption: String, CaseIterable, Identifiable {
    case askEachTime
    case oneHour
    case eightHours
    case untilTurnedOff

    var id: String { rawValue }

    var title: String {
        switch self {
        case .askEachTime: "Ask each time"
        case .oneHour: "1 hour"
        case .eightHours: "8 hours"
        case .untilTurnedOff: "Until I turn it off"
        }
    }
}

/// Backed by `users/{uid}.appearancePreference`. Not part of the original
/// design — a new addition per the brief.
enum AppearanceOption: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// `nil` lets SwiftUI follow the system setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
