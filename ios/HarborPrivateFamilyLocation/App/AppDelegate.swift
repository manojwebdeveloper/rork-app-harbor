@preconcurrency import FirebaseMessaging
import UIKit

/// Bridges UIKit's APNs registration callbacks to Firebase Messaging — SwiftUI's
/// `App` protocol has no equivalent hook, so this is the minimal delegate
/// needed for push registration to work.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("[HarborPrivateFamilyLocationPush] APNs registration failed: %@", error.localizedDescription)
    }
}
