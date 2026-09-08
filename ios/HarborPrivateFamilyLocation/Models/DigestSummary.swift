import FirebaseFirestore
import Foundation

/// Weekly digest data computed by the `generateWeeklyDigests` scheduled Cloud
/// Function, read from `circles/{circleId}/digests/{weekId}`.
struct DigestSummary {
    struct MemberSummary: Identifiable {
        let userID: String
        let checkIns: Int
        let places: Int
        let placeNames: [String]
        let alerts: Int

        var id: String { userID }
    }

    let id: String
    let weekStart: Date
    let weekEnd: Date
    let memberSummaries: [MemberSummary]

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let weekStart = (data["weekStart"] as? Timestamp)?.dateValue(),
              let weekEnd = (data["weekEnd"] as? Timestamp)?.dateValue() else {
            return nil
        }

        id = document.documentID
        self.weekStart = weekStart
        self.weekEnd = weekEnd
        memberSummaries = ((data["memberSummaries"] as? [[String: Any]]) ?? []).compactMap { entry in
            guard let userID = entry["userId"] as? String else { return nil }
            return MemberSummary(
                userID: userID,
                checkIns: entry["checkIns"] as? Int ?? 0,
                places: entry["places"] as? Int ?? 0,
                placeNames: entry["placeNames"] as? [String] ?? [],
                alerts: entry["alerts"] as? Int ?? 0
            )
        }
    }
}
