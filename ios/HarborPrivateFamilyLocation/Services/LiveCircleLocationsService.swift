import Combine
import CoreLocation
@preconcurrency import FirebaseDatabase
import Foundation

/// Reads back the live location ticks `LocationService` publishes, for
/// whichever single circle is currently selected on the map.
@MainActor
final class LiveCircleLocationsService: ObservableObject {
    struct LiveLocation {
        let coordinate: CLLocationCoordinate2D
        let horizontalAccuracy: Double?
        let speed: Double?
        let batteryLevel: Int?
        let isCharging: Bool
        let updatedAt: Date
    }

    @Published private(set) var locationsByUserID: [String: LiveLocation] = [:]

    private let isFirebaseConfigured: Bool
    private var observedRef: DatabaseReference?
    private var handle: DatabaseHandle?

    init(firebaseConfigured: Bool) {
        isFirebaseConfigured = firebaseConfigured
    }

    func observe(circleID: String?) {
        stop()
        guard isFirebaseConfigured, let circleID else { return }

        let ref = Database.database().reference(withPath: "locations/\(circleID)")
        observedRef = ref
        handle = ref.observe(.value) { [weak self] snapshot in
            Task { @MainActor in
                self?.apply(snapshot)
            }
        }
    }

    func stop() {
        if let observedRef, let handle {
            observedRef.removeObserver(withHandle: handle)
        }
        observedRef = nil
        handle = nil
        locationsByUserID = [:]
    }

    private func apply(_ snapshot: DataSnapshot) {
        var result: [String: LiveLocation] = [:]
        for case let child as DataSnapshot in snapshot.children {
            guard let value = child.value as? [String: Any],
                  let lat = value["lat"] as? Double,
                  let lng = value["lng"] as? Double,
                  let updatedAtMs = value["updatedAt"] as? Double else { continue }

            result[child.key] = LiveLocation(
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                horizontalAccuracy: value["horizontalAccuracy"] as? Double,
                speed: value["speed"] as? Double,
                batteryLevel: value["batteryLevel"] as? Int,
                isCharging: value["isCharging"] as? Bool ?? false,
                updatedAt: Date(timeIntervalSince1970: updatedAtMs / 1000)
            )
        }
        locationsByUserID = result
    }
}
