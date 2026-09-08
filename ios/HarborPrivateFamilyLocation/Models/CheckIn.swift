import FirebaseFirestore
import Foundation

/// A check-in message sent to a circle, with an optional sharing window.
/// Backed by `circles/{circleId}/checkIns/{checkInId}`.
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

        var seconds: TimeInterval? {
            switch self {
            case .fifteenMinutes: 15 * 60
            case .oneHour: 60 * 60
            case .eightHours: 8 * 60 * 60
            case .untilTurnedOff: nil
            }
        }
    }

    let id: String
    let userID: String
    var message: Message
    var customText: String?
    var sharingWindow: SharingWindow?
    var sentAt: Date

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let userID = data["userId"] as? String,
              let messageRaw = data["message"] as? String,
              let message = Message(rawValue: messageRaw),
              let sentAt = (data["sentAt"] as? Timestamp)?.dateValue() else {
            return nil
        }

        id = document.documentID
        self.userID = userID
        self.message = message
        customText = data["customText"] as? String
        sharingWindow = (data["sharingWindow"] as? String).flatMap(SharingWindow.init(rawValue:))
        self.sentAt = sentAt
    }
}
