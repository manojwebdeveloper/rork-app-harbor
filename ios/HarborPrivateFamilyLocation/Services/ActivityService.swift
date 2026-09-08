import Combine
@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseFirestore
@preconcurrency import FirebaseFunctions
import Foundation

/// Protocol-first per harbor-ios-standards.
protocol ActivityFeedSyncing: AnyObject {
    var checkIns: [CheckIn] { get }
    var serverActivity: [ServerActivityEntry] { get }
    var latestDigest: DigestSummary? { get }

    func observeCircle(circleID: String?)
    func sendCheckIn(
        circleID: String,
        message: CheckIn.Message,
        customText: String?,
        sharingWindow: CheckIn.SharingWindow?
    ) async throws
    func updateDigestPreferences(enabled: Bool, dayOfWeek: Int, hourUTC: Int) async throws
}

/// Owns the circle's check-ins, the server-authored activity feed (safe
/// broadcasts, system notices, arrival/departure/Smart Alert entries), and
/// the latest computed weekly digest.
@MainActor
final class ActivityService: ActivityFeedSyncing, ObservableObject {
    @Published private(set) var checkIns: [CheckIn] = []
    @Published private(set) var serverActivity: [ServerActivityEntry] = []
    @Published private(set) var latestDigest: DigestSummary?
    @Published var errorMessage: String?

    private let isFirebaseConfigured: Bool
    private let functionsRegion = "europe-west2"
    private var checkInsListener: ListenerRegistration?
    private var activityListener: ListenerRegistration?
    private var digestListener: ListenerRegistration?
    private var observedCircleID: String?

    init(firebaseConfigured: Bool) {
        isFirebaseConfigured = firebaseConfigured
    }

    func observeCircle(circleID: String?) {
        guard observedCircleID != circleID else { return }

        checkInsListener?.remove()
        activityListener?.remove()
        digestListener?.remove()
        checkInsListener = nil
        activityListener = nil
        digestListener = nil
        observedCircleID = circleID
        checkIns = []
        serverActivity = []
        latestDigest = nil

        guard isFirebaseConfigured, let circleID else { return }

        let startOfToday = Calendar.current.startOfDay(for: Date())
        let circleRef = Firestore.firestore().collection("circles").document(circleID)

        checkInsListener = circleRef.collection("checkIns")
            .whereField("sentAt", isGreaterThanOrEqualTo: Timestamp(date: startOfToday))
            .order(by: "sentAt")
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    self?.checkIns = snapshot?.documents.compactMap { CheckIn(document: $0) } ?? []
                }
            }

        activityListener = circleRef.collection("activity")
            .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfToday))
            .order(by: "createdAt")
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    self?.serverActivity = snapshot?.documents.compactMap { ServerActivityEntry(document: $0) } ?? []
                }
            }

        digestListener = circleRef.collection("digests")
            .order(by: "weekEnd", descending: true)
            .limit(to: 1)
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    self?.latestDigest = snapshot?.documents.first.flatMap { DigestSummary(document: $0) }
                }
            }
    }

    /// Duration is recorded on the check-in for display, but doesn't yet
    /// toggle a temporary override of the circle's own sharing setting —
    /// that's a follow-up, not implemented in this pass.
    func sendCheckIn(
        circleID: String,
        message: CheckIn.Message,
        customText: String?,
        sharingWindow: CheckIn.SharingWindow?
    ) async throws {
        guard isFirebaseConfigured, let uid = Auth.auth().currentUser?.uid else {
            throw ActivityServiceError.notSignedIn
        }
        var data: [String: Any] = [
            "userId": uid,
            "message": message.rawValue,
            "sentAt": FieldValue.serverTimestamp()
        ]
        if message == .custom, let customText, !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            data["customText"] = customText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let sharingWindow {
            data["sharingWindow"] = sharingWindow.rawValue
        }
        try await Firestore.firestore()
            .collection("circles").document(circleID).collection("checkIns").document()
            .setData(data)
    }

    func updateDigestPreferences(enabled: Bool, dayOfWeek: Int, hourUTC: Int) async throws {
        guard isFirebaseConfigured else { throw ActivityServiceError.notSignedIn }
        _ = try await Functions.functions(region: functionsRegion).httpsCallable("updateDigestPreferences").call([
            "enabled": enabled,
            "dayOfWeek": dayOfWeek,
            "hourUTC": hourUTC
        ])
    }
}

enum ActivityServiceError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn: "Sign in to use Activity."
        }
    }
}
