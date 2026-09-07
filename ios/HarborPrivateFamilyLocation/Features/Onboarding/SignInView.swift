import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(HarborPrivateFamilyLocationGradient.brand)
                    .frame(width: 124, height: 124)
                    .shadow(color: Color(.calmTeal).opacity(0.22), radius: 24, y: 12)
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 10) {
                Text("Welcome to HarborPrivateFamilyLocation")
                    .font(HarborPrivateFamilyLocationTypography.display)
                Text("Private location sharing for the people you trust.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 26)

            Spacer()

            VStack(spacing: 14) {
                SignInWithAppleButton(.signIn) { request in
                    authService.prepareSignInRequest(request)
                } onCompletion: { result in
                    Task { @MainActor in
                        await authService.completeSignIn(result)
                    }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 54)
                .clipShape(Capsule())
                .disabled(authService.isBusy)

                SecondaryButton(title: "Continue as guest", isEnabled: !authService.isBusy) {
                    Task { @MainActor in
                        await authService.signInAsGuest()
                    }
                }

                if authService.isBusy {
                    ProgressView("Signing in securely…")
                        .font(.footnote)
                }

                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color(.signalRed))
                        .multilineTextAlignment(.center)
                }

                Text("HarborPrivateFamilyLocation never sells your data. Your location is shared only with people you approve.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 26)
        }
        .background(Color(uiColor: .systemBackground))
    }
}
