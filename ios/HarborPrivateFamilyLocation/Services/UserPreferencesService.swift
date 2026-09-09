import Combine
@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseFirestore
import Foundation

/// Protocol-first per harbor-ios-standards.
protocol UserPreferencesSyncing: AnyObject {
    var notificationPreferences: NotificationPreferences { get }
    var sharingExpirationPreference: SharingExpirationOption { get }
    var appearancePreference: AppearanceOption { get }

    func observe(userID: String?)
    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws
    func updateSharingExpirationPreference(_ option: SharingExpirationOption) async throws
    func updateAppearancePreference(_ option: AppearanceOption) async throws
}

/// Owns the signed-in user's own settings — notifications, sharing
/// expiration default, and appearance. All three are plain fields on the
/// user's own `users/{uid}` document, which the user is already allowed to
/// write per firestore.rules; no new collection or rule needed.
@MainActor
final class UserPreferencesService: UserPreferencesSyncing, ObservableObject {
    @Published private(set) var notificationPreferences = NotificationPreferences()
    @Published private(set) var sharingExpirationPreference: SharingExpirationOption = .askEachTime
    @Published private(set) var appearancePreference: AppearanceOption = .system

    private let isFirebaseConfigured: Bool
    private var listener: ListenerRegistration?
    private var observedUserID: String?

    init(firebaseConfigured: Bool) {
        isFirebaseConfigured = firebaseConfigured
    }

    func observe(userID: String?) {
        guard observedUserID != userID else { return }
        listener?.remove()
        listener = nil
        observedUserID = userID
        notificationPreferences = NotificationPreferences()
        sharingExpirationPreference = .askEachTime
        appearancePreference = .system

        guard isFirebaseConfigured, let userID else { return }

        listener = Firestore.firestore().collection("users").document(userID)
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    guard let self, let data = snapshot?.data() else { return }
                    self.apply(data)
                }
            }
    }

    private func apply(_ data: [String: Any]) {
        notificationPreferences = NotificationPreferences(document: data["notificationPreferences"] as? [String: Any]) ?? notificationPreferences
        if let raw = data["sharingExpirationPreference"] as? String, let option = SharingExpirationOption(rawValue: raw) {
            sharingExpirationPreference = option
        }
        if let raw = data["appearancePreference"] as? String, let option = AppearanceOption(rawValue: raw) {
            appearancePreference = option
        }
    }

    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws {
        guard isFirebaseConfigured, let uid = Auth.auth().currentUser?.uid else {
            throw UserPreferencesError.notSignedIn
        }
        notificationPreferences = preferences
        try await Firestore.firestore().collection("users").document(uid).setData([
            "notificationPreferences": [
                "arrivalsAndDepartures": preferences.arrivalsAndDepartures,
                "checkIns": preferences.checkIns,
                "quietHoursEnabled": preferences.quietHoursEnabled,
                "quietHoursStart": preferences.quietHoursStart,
                "quietHoursEnd": preferences.quietHoursEnd,
                // Quiet Hours is evaluated server-side against the recipient's
                // own local time, so it needs to know which time zone that is.
                "timeZoneIdentifier": TimeZone.current.identifier
            ]
        ], merge: true)
    }

    func updateSharingExpirationPreference(_ option: SharingExpirationOption) async throws {
        guard isFirebaseConfigured, let uid = Auth.auth().currentUser?.uid else {
            throw UserPreferencesError.notSignedIn
        }
        sharingExpirationPreference = option
        try await Firestore.firestore().collection("users").document(uid)
            .setData(["sharingExpirationPreference": option.rawValue], merge: true)
    }

    func updateAppearancePreference(_ option: AppearanceOption) async throws {
        guard isFirebaseConfigured, let uid = Auth.auth().currentUser?.uid else {
            throw UserPreferencesError.notSignedIn
        }
        appearancePreference = option
        try await Firestore.firestore().collection("users").document(uid)
            .setData(["appearancePreference": option.rawValue], merge: true)
    }
}

enum UserPreferencesError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn: "Sign in to change this setting."
        }
    }
}
