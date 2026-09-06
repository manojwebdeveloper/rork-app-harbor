import SwiftUI

/// Placeholder — layout only. Shown right after joining or creating a circle.
struct JoinedView: View {
    let circleName: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Circle()
                .fill(HarborFamilyLocationGradient.brand)
                .frame(width: 58, height: 58)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }

            Text("Welcome to \(circleName)")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Nothing is shared yet. Next, you decide if and when to share your location.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            PrimaryButton(title: "Continue", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemBackground))
    }
}
