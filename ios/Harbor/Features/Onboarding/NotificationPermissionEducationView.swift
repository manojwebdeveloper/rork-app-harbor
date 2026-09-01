import SwiftUI

/// Placeholder — layout only. Explains notification value before the system prompt.
struct NotificationPermissionEducationView: View {
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Image(systemName: "bell.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(.calmTeal))
                .frame(width: 52, height: 52)
                .background(Color(.seaGlass))
                .clipShape(Circle())
                .padding(.top, 20)

            VStack(alignment: .leading, spacing: 8) {
                Text("Helpful updates, not noise")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                Text("Harbor sends only the updates your circle asks for:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                reason("house.fill", "Arrivals and departures", "For the Places you choose — home, school, work.")
                reason("checkmark", "Check-ins from your circle", "A quick “I'm safe” or “running late”, when they send one.")
                reason("xmark", "Never marketing", "No promotions, streaks or engagement nudges.")
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
