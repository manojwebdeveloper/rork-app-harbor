import CoreLocation
import Foundation

/// A saved place with an alert radius. Persistence arrives in a later pass.
struct Place: Identifiable, Hashable {
    enum Category: String, CaseIterable, Identifiable {
        case home = "Home"
        case school = "School"
        case work = "Work"
        case hotel = "Hotel"
        case airport = "Airport"
        case custom = "Custom"

        var id: String { rawValue }
    }

    let id: UUID
    var name: String
    var address: String
    var category: Category
    var coordinate: CLLocationCoordinate2D
    var radiusMeters: Double
    var arrivalAlertsEnabled: Bool
    var departureAlertsEnabled: Bool

    static func == (lhs: Place, rhs: Place) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
