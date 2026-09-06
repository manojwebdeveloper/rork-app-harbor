import SwiftUI

/// Placeholder — layout only. Confirmation toast shown after a check-in is sent.
struct CheckInConfirmationView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Circle()
                    .fill(Color(.clearSky))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    }

                Text("You're checked in")
                    .font(.headline)

                Text("Your circle can see this in Activity.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: 220)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.card, style: .continuous))
        }
        .transition(.opacity)
        .task {
            try? await Task.sleep(for: .seconds(2))
            onDismiss()
        }
    }
}
