import CoreLocation
import FirebaseFirestore
import Foundation

/// A saved place with an alert radius, backed by `circles/{circleId}/places/{placeId}`.
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

    let id: String
    var name: String
    var address: String
    var category: Category
    var coordinate: CLLocationCoordinate2D
    var radiusMeters: Double
    var arrivalAlertsEnabled: Bool
    var departureAlertsEnabled: Bool
    var createdBy: String

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let name = data["name"] as? String,
              let lat = data["lat"] as? Double,
              let lng = data["lng"] as? Double,
              let createdBy = data["createdBy"] as? String else {
            return nil
        }

        id = document.documentID
        self.name = name
        address = data["address"] as? String ?? ""
        category = Category(rawValue: data["category"] as? String ?? "") ?? .custom
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        radiusMeters = data["radiusMeters"] as? Double ?? 150
        arrivalAlertsEnabled = data["arrivalAlertsEnabled"] as? Bool ?? true
        departureAlertsEnabled = data["departureAlertsEnabled"] as? Bool ?? true
        self.createdBy = createdBy
    }

    static func == (lhs: Place, rhs: Place) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
