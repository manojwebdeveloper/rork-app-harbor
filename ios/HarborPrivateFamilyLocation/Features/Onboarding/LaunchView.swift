import SwiftUI

/// Splash shown while HarborPrivateFamilyLocation restores the signed-in session.
struct LaunchView: View {
    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Image("AppIconMark")
                .resizable()
                .scaledToFill()
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: Color(.calmTeal).opacity(0.30), radius: 20, y: 10)

            Text("HarborPrivateFamilyLocation")
                .font(HarborPrivateFamilyLocationTypography.title)

            Spacer()

            ProgressView()
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.launchBackground))
    }
}

/// Shown when no GoogleService-Info.plist is bundled with the build.
struct FirebaseSetupRequiredView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Firebase setup required", systemImage: "flame.fill")
        } description: {
            Text("Add GoogleService-Info.plist to HarborPrivateFamilyLocation/Resources and rebuild the app.")
        } actions: {
            Text("See docs/firebase-testing-setup.md in the repository.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(.calmTeal))
        }
    }
}
