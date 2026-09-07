@preconcurrency import AuthenticationServices
import Combine
import CryptoKit
@preconcurrency import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
@preconcurrency import FirebaseFunctions
import Foundation

/// Configures Firebase only when a real GoogleService-Info.plist is bundled.
/// This keeps local design previews usable before the Firebase project is connected.
enum FirebaseBootstrap {
    @discardableResult
    static func configureIfPossible() -> Bool {
        if FirebaseApp.app() != nil {
            return true
        }

        guard
            let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let options = FirebaseOptions(contentsOfFile: path)
        else {
            return false
        }

        FirebaseApp.configure(options: options)
        return true
    }
}

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var user: FirebaseAuth.User?
    @Published private(set) var isLoading: Bool
    @Published private(set) var isBusy = false
    @Published var errorMessage: String?

    let isFirebaseConfigured: Bool

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    private let functionsRegion = "europe-west2"

    init(firebaseConfigured: Bool) {
        isFirebaseConfigured = firebaseConfigured
        isLoading = firebaseConfigured

        guard firebaseConfigured else {
            user = nil
            isLoading = false
            return
        }

        user = Auth.auth().currentUser
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isLoading = false
            }
        }
    }

    var displayName: String {
        let value = user?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value, !value.isEmpty {
            return value
        }
        return user?.isAnonymous == true ? "Guest" : "HarborPrivateFamilyLocation member"
    }

    var emailAddress: String? {
        user?.email
    }

    func prepareSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        prepareAppleRequest(request)
    }

    func completeSignIn(_ result: Result<ASAuthorization, Error>) async {
        guard isFirebaseConfigured else { return }

        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            let payload = try makeAppleCredential(from: result)
            let authResult = try await Auth.auth().signIn(with: payload.credential)
            try await upsertProfile(for: authResult.user)
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    /// Preview/testing path that skips Sign in with Apple. Creates a real Firebase
    /// session using anonymous auth so circles and invitations work end to end.
    func signInAsGuest() async {
        guard isFirebaseConfigured else { return }

        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            let authResult = try await Auth.auth().signInAnonymously()
            NSLog("[HarborPrivateFamilyLocationAuth] Guest sign-in succeeded uid=%@", authResult.user.uid)
            // Profile creation is best-effort for guests: Firestore rules may only
            // allow permanent accounts, and that must not block the preview session.
            do {
                try await upsertProfile(for: authResult.user)
            } catch {
                NSLog("[HarborPrivateFamilyLocationAuth] Guest profile write skipped: %@", error.localizedDescription)
            }
        } catch {
            let nsError = error as NSError
            NSLog(
                "[HarborPrivateFamilyLocationAuth] Guest sign-in failed code=%ld domain=%@ details=%@",
                nsError.code,
                nsError.domain,
                String(describing: nsError.userInfo)
            )
            errorMessage = readableMessage(for: error)
        }
    }

    func signOut() {
        guard isFirebaseConfigured else { return }

        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    func prepareAccountDeletionRequest(_ request: ASAuthorizationAppleIDRequest) {
        prepareAppleRequest(request)
    }

    /// Re-authenticates with Apple, revokes the Apple token and delegates data cleanup
    /// plus Firebase Auth deletion to the trusted callable function.
    func completeAccountDeletion(_ result: Result<ASAuthorization, Error>) async -> Bool {
        guard isFirebaseConfigured, let currentUser = Auth.auth().currentUser else {
            errorMessage = "No signed-in account was found."
            return false
        }

        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            let payload = try makeAppleCredential(from: result)
            _ = try await currentUser.reauthenticate(with: payload.credential)

            guard let authorizationCode = payload.authorizationCode else {
                throw AuthFlowError.missingAuthorizationCode
            }

            try await Auth.auth().revokeToken(withAuthorizationCode: authorizationCode)

            let callable = Functions.functions(region: functionsRegion).httpsCallable("deleteAccount")
            _ = try await callable.call([:])

            // The server deletes the Firebase user. Clearing the local session makes the
            // UI transition immediately even before the auth-state listener refreshes.
            try? Auth.auth().signOut()
            user = nil
            return true
        } catch {
            errorMessage = readableMessage(for: error)
            return false
        }
    }

    private func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        do {
            let nonce = try Self.randomNonceString()
            currentNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = Self.sha256(nonce)
        } catch {
            currentNonce = nil
            errorMessage = readableMessage(for: error)
        }
    }

    private func makeAppleCredential(
        from result: Result<ASAuthorization, Error>
    ) throws -> AppleCredentialPayload {
        let authorization = try result.get()

        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthFlowError.invalidAppleCredential
        }
        guard let nonce = currentNonce else {
            throw AuthFlowError.missingNonce
        }
        guard let tokenData = appleCredential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            throw AuthFlowError.missingIdentityToken
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: token,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )

        let authorizationCode = appleCredential.authorizationCode
            .flatMap { String(data: $0, encoding: .utf8) }

        currentNonce = nil
        return AppleCredentialPayload(
            credential: credential,
            authorizationCode: authorizationCode
        )
    }

    private func upsertProfile(for user: FirebaseAuth.User) async throws {
        let data: [String: Any] = [
            "uid": user.uid,
            "displayName": user.displayName ?? "",
            "email": user.email ?? "",
            "updatedAt": FieldValue.serverTimestamp(),
            "createdAt": FieldValue.serverTimestamp()
        ]

        try await Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .setData(data, merge: true)
    }

    private func readableMessage(for error: Error) -> String {
        if let authorizationError = error as? ASAuthorizationError,
           authorizationError.code == .canceled {
            return "Sign in was cancelled."
        }

        let nsError = error as NSError

        if nsError.code == AuthErrorCode.operationNotAllowed.rawValue {
            return Self.signInMethodDisabledMessage
        }

        // A Firebase project whose Authentication section has never been set up returns
        // CONFIGURATION_NOT_FOUND, which the SDK surfaces as an opaque "internal error".
        if nsError.code == AuthErrorCode.internalError.rawValue {
            if String(describing: nsError.userInfo).contains("CONFIGURATION_NOT_FOUND") {
                return Self.signInMethodDisabledMessage
            }
            return "Firebase rejected the sign-in request. Confirm Authentication is set up for this project, then try again."
        }

        if nsError.code == AuthErrorCode.networkError.rawValue {
            return "No connection to Firebase. Check your network and try again."
        }

        return error.localizedDescription
    }

    private static let signInMethodDisabledMessage = """
    Guest sign-in is not enabled for this Firebase project. \
    Open Firebase console → Authentication → Sign-in method, enable Anonymous, then try again.
    """

    private static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func randomNonceString(length: Int = 32) throws -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard status == errSecSuccess else {
            throw AuthFlowError.nonceGenerationFailed(status)
        }

        let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { characters[Int($0) % characters.count] })
    }
}

private struct AppleCredentialPayload {
    let credential: AuthCredential
    let authorizationCode: String?
}

private enum AuthFlowError: LocalizedError {
    case invalidAppleCredential
    case missingNonce
    case missingIdentityToken
    case missingAuthorizationCode
    case nonceGenerationFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidAppleCredential:
            "Apple did not return a valid credential."
        case .missingNonce:
            "The secure sign-in request expired. Please try again."
        case .missingIdentityToken:
            "Apple did not return an identity token."
        case .missingAuthorizationCode:
            "Apple did not return the code required to delete this account."
        case .nonceGenerationFailed:
            "A secure sign-in request could not be created."
        }
    }
}
