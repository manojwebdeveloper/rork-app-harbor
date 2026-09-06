import Foundation

/// A single row in the Activity timeline.
struct ActivityEntry: Identifiable, Hashable {
    enum Kind: String, CaseIterable, Identifiable {
        case place = "Places"
        case checkIn = "Check-ins"
        case system = "System"

        var id: String { rawValue }
    }

    let id: UUID
    var date: Date
    var title: String
    var detail: String
    var kind: Kind
}
