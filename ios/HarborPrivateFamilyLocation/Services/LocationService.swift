import Combine
import CoreLocation
@preconcurrency import FirebaseDatabase
@preconcurrency import FirebaseFirestore
import Foundation
import UIKit

/// Publishes the signed-in user's location to Realtime Database for every circle
/// they are actively sharing with, throttled to at most once every
/// `minimumPublishInterval` seconds unless the device has moved more than
/// `significantMovementMeters` — the cost/battery requirement from the backend
/// brief, not merely a nice-to-have.
@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var isSharingPaused = false
    /// Circle IDs the signed-in user currently shares their location with,
    /// derived from every `sharingEnabled` membership document they hold.
    @Published private(set) var sharingCircleIDs: Set<String> = []

    private let manager = CLLocationManager()
    private let isFirebaseConfigured: Bool
    private var membershipListener: ListenerRegistration?
    private var observedUserID: String?

    private var lastPublishedAt: Date?
    private var lastPublishedLocation: CLLocation?
    private static let minimumPublishInterval: TimeInterval = 12
    private static let significantMovementMeters: CLLocationDistance = 40

    init(firebaseConfigured: Bool) {
        isFirebaseConfigured = firebaseConfigured
        authorizationStatus = CLLocationManager().authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 25
        manager.pausesLocationUpdatesAutomatically = true
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func setSharingPaused(_ isPaused: Bool) {
        isSharingPaused = isPaused
        updateTrackingState()
    }

    /// Tracks every circle-membership document the user holds (a collection-group
    /// query scoped to their own `userId`, which their own Firestore rules already
    /// allow) so sharing follows the per-circle toggle without a listener per circle.
    func observeSharingCircles(for userID: String?) {
        guard observedUserID != userID else { return }

        membershipListener?.remove()
        membershipListener = nil
        observedUserID = userID
        sharingCircleIDs = []
        updateTrackingState()

        guard isFirebaseConfigured, let userID else { return }

        membershipListener = Firestore.firestore()
            .collectionGroup("members")
            .whereField("userId", isEqualTo: userID)
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    guard let self else { return }
                    let ids: [String] = (snapshot?.documents ?? []).compactMap { document in
                        guard document.get("sharingEnabled") as? Bool == true else { return nil }
                        return document.reference.parent.parent?.documentID
                    }
                    self.sharingCircleIDs = Set(ids)
                    self.updateTrackingState()
                }
            }
    }

    private func updateTrackingState() {
        let shouldTrack = isFirebaseConfigured && isAuthorized && !isSharingPaused && !sharingCircleIDs.isEmpty
        manager.allowsBackgroundLocationUpdates = shouldTrack && authorizationStatus == .authorizedAlways
        if shouldTrack {
            manager.startUpdatingLocation()
        } else {
            manager.stopUpdatingLocation()
        }
    }

    private func publishIfNeeded(_ location: CLLocation) {
        guard isFirebaseConfigured, !sharingCircleIDs.isEmpty, let userID = observedUserID else { return }

        let now = Date()
        if let lastPublishedAt, let lastPublishedLocation {
            let elapsed = now.timeIntervalSince(lastPublishedAt)
            let moved = location.distance(from: lastPublishedLocation)
            guard elapsed >= Self.minimumPublishInterval || moved >= Self.significantMovementMeters else {
                return
            }
        }
        lastPublishedAt = now
        lastPublishedLocation = location

        var payload: [String: Any] = [
            "lat": location.coordinate.latitude,
            "lng": location.coordinate.longitude,
            "horizontalAccuracy": location.horizontalAccuracy,
            "updatedAt": ServerValue.timestamp(),
        ]
        if location.course >= 0 { payload["heading"] = location.course }
        if location.speed >= 0 { payload["speed"] = location.speed }
        if UIDevice.current.batteryLevel >= 0 {
            payload["batteryLevel"] = Int(UIDevice.current.batteryLevel * 100)
        }
        payload["isCharging"] = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full

        for circleID in sharingCircleIDs {
            Database.database().reference(withPath: "locations/\(circleID)/\(userID)").setValue(payload)
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            self.updateTrackingState()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.publishIfNeeded(location)
        }
    }
}
