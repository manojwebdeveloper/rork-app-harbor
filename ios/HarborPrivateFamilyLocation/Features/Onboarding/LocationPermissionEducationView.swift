import SwiftUI

/// Placeholder — layout only. Explains why HarborPrivateFamilyLocation asks for location before the system prompt.
struct LocationPermissionEducationView: View {
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Image(systemName: "location.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(.calmTeal))
                .frame(width: 52, height: 52)
                .background(Color(.seaGlass))
                .clipShape(Circle())
                .padding(.top, 20)

            VStack(alignment: .leading, spacing: 8) {
                Text("Share your location with your circle")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                Text("HarborPrivateFamilyLocation only works when you choose to share. Here is what that means:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                reason("mappin.and.ellipse", "Why we ask", "The map and arrival updates need your location to work.")
                reason("eye.fill", "Only your circle sees it", "Shared with your circle — never advertisers or strangers.")
                reason("pause.fill", "Pause anytime", "One tap pauses sharing, from the map or the You tab.")
                reason("checkmark", "Everyone agrees", "Each member of your circle chose to share, just like you.")
            }

            Spacer()

            VStack(spacing: 10) {
                PrimaryButton(title: "Continue", action: onContinue)
                Button("Not now", action: onSkip)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.calmTeal))
                    .frame(height: 44)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(Color(uiColor: .systemBackground))
    }

    private func reason(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(.calmTeal))
                .frame(width: 28, height: 28)
                .background(Color(.seaGlass).opacity(0.7))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
