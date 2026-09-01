import Foundation

/// A check-in message sent to a circle, with an optional sharing window.
struct CheckIn: Identifiable, Hashable {
    enum Message: String, CaseIterable, Identifiable {
        case safe = "I'm safe"
        case arrived = "I've arrived"
        case onMyWay = "On my way"
        case runningLate = "Running late"
        case custom = "Custom message…"

        var id: String { rawValue }
    }

    enum SharingWindow: String, CaseIterable, Identifiable {
        case fifteenMinutes = "15 minutes"
        case oneHour = "1 hour"
        case eightHours = "8 hours"
        case untilTurnedOff = "Until I turn it off"

        var id: String { rawValue }
    }

    let id: UUID
    var message: Message
    var customText: String?
    var sharingWindow: SharingWindow?
    var sentAt: Date
}
