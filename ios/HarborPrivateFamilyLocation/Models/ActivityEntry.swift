import FirebaseFirestore
import Foundation

/// A server-authored row in `circles/{circleId}/activity` — safe broadcasts,
/// system notices, and arrival/departure/Smart Alert entries written by
/// Cloud Functions. The Activity tab merges this with the circle's own
/// `checkIns` to build its timeline.
struct ServerActivityEntry: Identifiable {
    let id: String
    let kind: String
    let memberID: String?
    let title: String
    let detail: String
    let createdAt: Date

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let kind = data["kind"] as? String,
              let title = data["title"] as? String,
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
            return nil
        }

        id = document.documentID
        self.kind = kind
        memberID = data["memberId"] as? String
        self.title = title
        detail = data["detail"] as? String ?? ""
        self.createdAt = createdAt
    }
}
