import FirebaseFirestore
import Foundation

/// A Smart Alert rule for one place, backed by
/// `circles/{circleId}/places/{placeId}/alertRules/{ruleId}`.
///
/// Raw values are the exact strings `SmartAlertRuleBuilderView` already shows
/// in its pickers, so the view's local `@State` strings are valid enum raw
/// values with no translation layer.
struct SmartAlertRule: Identifiable, Hashable {
    enum Event: String, CaseIterable, Identifiable {
        case arrives, leaves
        case stillHere = "is still here"
        case isHome = "is home"
        var id: String { rawValue }
    }

    enum Comparator: String, CaseIterable, Identifiable {
        case after, before, by
        var id: String { rawValue }
    }

    enum Frequency: String, CaseIterable, Identifiable {
        case everyTime = "Every time"
        case onceADay = "Once a day"
        case weeklySummary = "Weekly summary"
        var id: String { rawValue }
    }

    /// "anyone", "not_everyone", or a real circle member's uid.
    static let anyonePersonID = "anyone"
    static let notEveryonePersonID = "not_everyone"

    let id: String
    var personID: String
    var personLabel: String
    var event: Event
    var comparator: Comparator
    /// Minutes since local midnight (e.g. 18:00 -> 1080).
    var timeMinutes: Int
    var frequency: Frequency
    /// 0 = Sunday ... 6 = Saturday, matching `SmartAlertRuleBuilderView.dayLabels`.
    var days: Set<Int>
    var isOn: Bool
    let createdBy: String

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let personID = data["personId"] as? String,
              let eventRaw = data["event"] as? String,
              let event = Event(rawValue: eventRaw),
              let comparatorRaw = data["comparator"] as? String,
              let comparator = Comparator(rawValue: comparatorRaw),
              let timeMinutes = data["timeMinutes"] as? Int,
              let frequencyRaw = data["frequency"] as? String,
              let frequency = Frequency(rawValue: frequencyRaw),
              let createdBy = data["createdBy"] as? String else {
            return nil
        }

        id = document.documentID
        self.personID = personID
        personLabel = data["personLabel"] as? String ?? "Someone"
        self.event = event
        self.comparator = comparator
        self.timeMinutes = timeMinutes
        self.frequency = frequency
        days = Set((data["days"] as? [Int]) ?? [])
        isOn = data["isOn"] as? Bool ?? true
        self.createdBy = createdBy
    }

    /// "Notify me if Emily arrives after 6:00 PM" — matches the builder's sentence exactly.
    var sentence: String {
        "Notify me if \(personLabel) \(event.rawValue) \(comparator.rawValue) \(timeText)"
    }

    var timeText: String {
        var components = DateComponents()
        components.hour = timeMinutes / 60
        components.minute = timeMinutes % 60
        let date = Calendar.current.date(from: components) ?? Date()
        return Self.timeFormatter.string(from: date)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    /// Parses one of the builder's fixed time-picker strings ("6:00 PM") into minutes since midnight.
    static func minutes(fromPickerTime text: String) -> Int? {
        guard let date = timeFormatter.date(from: text) else { return nil }
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return nil }
        return hour * 60 + minute
    }
}
