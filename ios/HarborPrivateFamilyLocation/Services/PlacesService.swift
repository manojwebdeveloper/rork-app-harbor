import Combine
import CoreLocation
@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseFirestore
import Foundation

/// Protocol-first per harbor-ios-standards: lets Places features be faked in
/// previews/tests without touching Firebase or CoreLocation.
protocol PlacesSyncing: AnyObject {
    var places: [Place] { get }
    var alertRulesByPlaceID: [String: [SmartAlertRule]] { get }

    func observePlaces(circleID: String?)
    func observeAlertRules(circleID: String, placeID: String)

    @discardableResult
    func addPlace(
        circleID: String,
        name: String,
        address: String,
        category: Place.Category,
        coordinate: CLLocationCoordinate2D,
        radiusMeters: Double,
        arrivalAlertsEnabled: Bool,
        departureAlertsEnabled: Bool
    ) async throws -> String

    func setPlaceAlerts(circleID: String, placeID: String, arrivalAlertsEnabled: Bool, departureAlertsEnabled: Bool) async throws
    func deletePlace(circleID: String, placeID: String) async throws

    @discardableResult
    func addAlertRule(
        circleID: String,
        placeID: String,
        personID: String,
        personLabel: String,
        event: SmartAlertRule.Event,
        comparator: SmartAlertRule.Comparator,
        timeMinutes: Int,
        frequency: SmartAlertRule.Frequency,
        days: Set<Int>
    ) async throws -> String

    func setAlertRule(isOn: Bool, circleID: String, placeID: String, ruleID: String) async throws
    func deleteAlertRule(circleID: String, placeID: String, ruleID: String) async throws
}

/// Owns saved places, their Smart Alert rules, and the on-device geofences
/// that report arrivals/departures. Rule *evaluation* happens server-side
/// (`evaluateSmartAlert` Cloud Function) — this service only reports what the
/// device observed, per harbor-ios-standards ("Cloud Functions handle
/// anything that shouldn't trust the client").
@MainActor
final class PlacesService: NSObject, PlacesSyncing, ObservableObject {
    @Published private(set) var places: [Place] = []
    @Published private(set) var alertRulesByPlaceID: [String: [SmartAlertRule]] = [:]

    private let isFirebaseConfigured: Bool
    private var placesListener: ListenerRegistration?
    private var alertRuleListeners: [String: ListenerRegistration] = [:]
    private var observedCircleID: String?

    private let regionMonitor = CLLocationManager()

    init(firebaseConfigured: Bool) {
        isFirebaseConfigured = firebaseConfigured
        super.init()
        regionMonitor.delegate = self
    }

    func observePlaces(circleID: String?) {
        guard observedCircleID != circleID else { return }

        placesListener?.remove()
        placesListener = nil
        for (_, listener) in alertRuleListeners { listener.remove() }
        alertRuleListeners.removeAll()
        alertRulesByPlaceID.removeAll()
        observedCircleID = circleID
        places = []
        stopMonitoringAllRegions()

        guard isFirebaseConfigured, let circleID else { return }

        placesListener = Firestore.firestore()
            .collection("circles").document(circleID).collection("places")
            .order(by: "createdAt")
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.places = snapshot?.documents.compactMap { Place(document: $0) } ?? []
                    self.updateMonitoredRegions()
                }
            }
    }

    func observeAlertRules(circleID: String, placeID: String) {
        guard alertRuleListeners[placeID] == nil, isFirebaseConfigured else { return }

        alertRuleListeners[placeID] = Firestore.firestore()
            .collection("circles").document(circleID)
            .collection("places").document(placeID).collection("alertRules")
            .order(by: "createdAt")
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.alertRulesByPlaceID[placeID] = snapshot?.documents.compactMap { SmartAlertRule(document: $0) } ?? []
                }
            }
    }

    @discardableResult
    func addPlace(
        circleID: String,
        name: String,
        address: String,
        category: Place.Category,
        coordinate: CLLocationCoordinate2D,
        radiusMeters: Double,
        arrivalAlertsEnabled: Bool,
        departureAlertsEnabled: Bool
    ) async throws -> String {
        guard isFirebaseConfigured, let uid = Auth.auth().currentUser?.uid else {
            throw PlacesServiceError.notSignedIn
        }
        let ref = Firestore.firestore().collection("circles").document(circleID).collection("places").document()
        try await ref.setData([
            "name": name,
            "address": address,
            "category": category.rawValue,
            "lat": coordinate.latitude,
            "lng": coordinate.longitude,
            "radiusMeters": radiusMeters,
            "arrivalAlertsEnabled": arrivalAlertsEnabled,
            "departureAlertsEnabled": departureAlertsEnabled,
            "createdBy": uid,
            "createdAt": FieldValue.serverTimestamp()
        ])
        return ref.documentID
    }

    func setPlaceAlerts(circleID: String, placeID: String, arrivalAlertsEnabled: Bool, departureAlertsEnabled: Bool) async throws {
        guard isFirebaseConfigured else { throw PlacesServiceError.notSignedIn }
        try await Firestore.firestore()
            .collection("circles").document(circleID).collection("places").document(placeID)
            .setData([
                "arrivalAlertsEnabled": arrivalAlertsEnabled,
                "departureAlertsEnabled": departureAlertsEnabled
            ], merge: true)
    }

    func deletePlace(circleID: String, placeID: String) async throws {
        guard isFirebaseConfigured else { throw PlacesServiceError.notSignedIn }
        try await Firestore.firestore()
            .collection("circles").document(circleID).collection("places").document(placeID)
            .delete()
    }

    @discardableResult
    func addAlertRule(
        circleID: String,
        placeID: String,
        personID: String,
        personLabel: String,
        event: SmartAlertRule.Event,
        comparator: SmartAlertRule.Comparator,
        timeMinutes: Int,
        frequency: SmartAlertRule.Frequency,
        days: Set<Int>
    ) async throws -> String {
        guard isFirebaseConfigured, let uid = Auth.auth().currentUser?.uid else {
            throw PlacesServiceError.notSignedIn
        }
        let ref = Firestore.firestore()
            .collection("circles").document(circleID)
            .collection("places").document(placeID).collection("alertRules").document()
        try await ref.setData([
            "personId": personID,
            "personLabel": personLabel,
            "event": event.rawValue,
            "comparator": comparator.rawValue,
            "timeMinutes": timeMinutes,
            "frequency": frequency.rawValue,
            "days": Array(days),
            "isOn": true,
            "createdBy": uid,
            "createdAt": FieldValue.serverTimestamp()
        ])
        return ref.documentID
    }

    func setAlertRule(isOn: Bool, circleID: String, placeID: String, ruleID: String) async throws {
        guard isFirebaseConfigured else { throw PlacesServiceError.notSignedIn }
        try await Firestore.firestore()
            .collection("circles").document(circleID)
            .collection("places").document(placeID).collection("alertRules").document(ruleID)
            .setData(["isOn": isOn], merge: true)
    }

    func deleteAlertRule(circleID: String, placeID: String, ruleID: String) async throws {
        guard isFirebaseConfigured else { throw PlacesServiceError.notSignedIn }
        try await Firestore.firestore()
            .collection("circles").document(circleID)
            .collection("places").document(placeID).collection("alertRules").document(ruleID)
            .delete()
    }

    // MARK: - Geofencing

    /// iOS allows at most 20 monitored regions app-wide, so only the places
    /// belonging to the currently selected circle are monitored — monitoring
    /// every circle's places at once isn't attempted in this pass.
    private func updateMonitoredRegions() {
        stopMonitoringAllRegions()
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self),
              regionMonitor.authorizationStatus == .authorizedAlways || regionMonitor.authorizationStatus == .authorizedWhenInUse else {
            return
        }

        let maxDistance = regionMonitor.maximumRegionMonitoringDistance
        for place in places.prefix(20) where place.arrivalAlertsEnabled || place.departureAlertsEnabled {
            let radius = maxDistance > 0 ? min(max(place.radiusMeters, 25), maxDistance) : max(place.radiusMeters, 25)
            let region = CLCircularRegion(center: place.coordinate, radius: radius, identifier: place.id)
            region.notifyOnEntry = place.arrivalAlertsEnabled
            region.notifyOnExit = place.departureAlertsEnabled
            regionMonitor.startMonitoring(for: region)
        }
    }

    private func stopMonitoringAllRegions() {
        for region in regionMonitor.monitoredRegions {
            regionMonitor.stopMonitoring(for: region)
        }
    }

    private func recordCrossing(placeID: String, type: String) {
        guard isFirebaseConfigured, let circleID = observedCircleID, let uid = Auth.auth().currentUser?.uid else { return }

        let now = Date()
        let calendar = Calendar.current
        let localMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        // Calendar.weekday is 1 = Sunday ... 7 = Saturday; the day picker is 0-based.
        let localDayOfWeek = calendar.component(.weekday, from: now) - 1

        Firestore.firestore()
            .collection("circles").document(circleID)
            .collection("places").document(placeID).collection("events").document()
            .setData([
                "memberId": uid,
                "type": type,
                "localMinutes": localMinutes,
                "localDayOfWeek": localDayOfWeek,
                "occurredAt": FieldValue.serverTimestamp()
            ])
    }
}

extension PlacesService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in self.recordCrossing(placeID: region.identifier, type: "arrival") }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in self.recordCrossing(placeID: region.identifier, type: "departure") }
    }
}

enum PlacesServiceError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn: "Sign in to manage places."
        }
    }
}
