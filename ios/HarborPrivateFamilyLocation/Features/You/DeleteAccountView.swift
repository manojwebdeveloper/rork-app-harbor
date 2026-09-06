import AuthenticationServices
import SwiftUI

struct DeleteAccountView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var acknowledged = false
    @State private var deleted = false

    var body: some View {
        List {
            Section {
                Label(
                    "Deleting your account removes everything, for good",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.headline)
                .foregroundStyle(Color(.signalRed))

                Text("Your location history and check-ins, your Places and alert settings, your membership in every circle, and your account details are removed within 30 days.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Before deleting") {
                Label("Apple requires a fresh sign-in before account deletion.", systemImage: "apple.logo")
                Label("Any App Store subscription must be managed separately in Apple Settings.", systemImage: "creditcard")
                Label("This action cannot be undone.", systemImage: "arrow.uturn.backward.slash")
            }

            Section {
                Toggle(
                    "I understand that my account and circle data will be permanently deleted.",
                    isOn: $acknowledged
                )
            }

            Section {
                SignInWithAppleButton(.continue) { request in
                    authService.prepareAccountDeletionRequest(request)
                } onCompletion: { result in
                    Task { @MainActor in
                        deleted = await authService.completeAccountDeletion(result)
                        if deleted {
                            dismiss()
                        }
                    }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 52)
                .clipShape(Capsule())
                .disabled(!acknowledged || authService.isBusy)

                if authService.isBusy {
                    ProgressView("Deleting your account…")
                }
            } footer: {
                Text("The button re-authenticates with Apple, revokes HarborPrivateFamilyLocation’s Apple token and securely asks Firebase to delete your account data.")
            }

            if let errorMessage = authService.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(Color(.signalRed))
                }
            }
        }
        .navigationTitle("Delete your account")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(authService.isBusy)
    }
}
