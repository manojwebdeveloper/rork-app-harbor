import SwiftUI

/// The "I'm Safe" pill that sits above the member strip on the map.
struct SafeBroadcastButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("I’m Safe")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(Color(.calmTeal))
            .clipShape(Capsule())
            .shadow(color: Color(.calmTeal).opacity(0.35), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tell your circle you are safe")
    }
}

/// Confirmation banner shown after the safe broadcast is sent.
struct SafeBroadcastToast: View {
    let circleName: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(.calmTeal))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Your circle knows you’re safe")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.primary)
                    Text("Sent to \(circleName) · no location shared")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 18, y: 6)
        }
        .buttonStyle(.plain)
    }
}
