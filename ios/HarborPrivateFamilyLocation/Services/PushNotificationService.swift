import Combine
@preconcurrency import FirebaseFunctions
@preconcurrency import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

/// Protocol-first per harbor-ios-standards.
protocol PushTokenRegistering: AnyObject {
    func requestAuthorizationAndRegister() async
}

/// Requests notification permission, registers for remote notifications, and
/// forwards the resulting FCM token to the `registerPushToken` Cloud
/// Function. Actually *receiving* a push additionally needs an APNs
/// Authentication Key uploaded to Firebase Cloud Messaging, and the Push
/// Notifications capability/entitlement on the App ID — both Apple Developer
/// Portal steps outside this session's access. This service only owns the
/// client-side registration half.
@MainActor
final class PushNotificationService: NSObject, ObservableObject, PushTokenRegistering {
    @Published private(set) var isAuthorized = false
    @Published private(set) var lastRegistrationError: String?

    private let isFirebaseConfigured: Bool
    private let functionsRegion = "europe-west2"
    private var registeredToken: String?

    init(firebaseConfigured: Bool) {
        isFirebaseConfigured = firebaseConfigured
        super.init()
        guard isFirebaseConfigured else { return }
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorizationAndRegister() async {
        guard isFirebaseConfigured else { return }
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            guard granted else { return }
            UIApplication.shared.registerForRemoteNotifications()
        } catch {
            isAuthorized = false
            lastRegistrationError = error.localizedDescription
        }
    }

    fileprivate func handleFCMToken(_ token: String?) {
        guard isFirebaseConfigured, let token, token != registeredToken else { return }
        registeredToken = token
        Task {
            do {
                _ = try await Functions.functions(region: functionsRegion)
                    .httpsCallable("registerPushToken")
                    .call(["token": token])
            } catch {
                // Best-effort: a signed-out session or a transient network
                // error shouldn't crash the app — the token registers again
                // on the next refresh or launch.
                lastRegistrationError = error.localizedDescription
            }
        }
    }
}

extension PushNotificationService: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task { @MainActor in self.handleFCMToken(fcmToken) }
    }
}

extension PushNotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound, .badge]
    }
}
