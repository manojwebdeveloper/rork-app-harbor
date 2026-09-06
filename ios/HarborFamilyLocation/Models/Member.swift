import CoreLocation
import FirebaseFirestore
import Foundation
import SwiftUI

/// Presentation model for a person shown on the map and in carousels.
struct HarborFamilyLocationMember: Identifiable, Hashable {
    enum Presence: String {
        case live = "Live now"
        case recent = "Updated recently"
        case arrived = "Arrived"
        case travelling = "On the way"
        case delayed = "Location delayed"
        case offline = "Phone offline"
        case paused = "Sharing paused"
    }

    let id: UUID
    var name: String
    var initials: String
    var coordinate: CLLocationCoordinate2D
    var locationName: String
    var batteryLevel: Int
    var presence: Presence
    var tint: Color
    var etaText: String?

    static func == (lhs: HarborFamilyLocationMember, rhs: HarborFamilyLocationMember) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// A circle member as stored in Firestore.
struct FirebaseCircleMember: Identifiable, Hashable {
    let id: String
    let displayName: String
    let role: String
    let sharingEnabled: Bool
    let joinedAt: Date?

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let userID = data["userId"] as? String,
              let role = data["role"] as? String else {
            return nil
        }

        id = userID
        displayName = (data["displayName"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty ?? "HarborFamilyLocation member"
        self.role = role
        sharingEnabled = data["sharingEnabled"] as? Bool ?? false
        joinedAt = (data["joinedAt"] as? Timestamp)?.dateValue()
    }
}

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
