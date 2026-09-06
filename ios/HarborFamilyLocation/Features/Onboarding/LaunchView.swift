import SwiftUI

/// Splash shown while HarborFamilyLocation restores the signed-in session.
struct LaunchView: View {
    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(HarborFamilyLocationGradient.brand)
                .frame(width: 76, height: 76)
                .overlay {
                    Image(systemName: "person.3.sequence.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                }

            Text("HarborFamilyLocation")
                .font(HarborFamilyLocationTypography.title)

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
            Text("Add GoogleService-Info.plist to HarborFamilyLocation/Resources and rebuild the app.")
        } actions: {
            Text("See docs/firebase-testing-setup.md in the repository.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(.calmTeal))
        }
    }
}
