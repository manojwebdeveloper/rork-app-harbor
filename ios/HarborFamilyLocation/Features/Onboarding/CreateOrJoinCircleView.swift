import SwiftUI

/// Placeholder — layout only. The caller owns routing.
struct CreateOrJoinCircleView: View {
    let onCreate: () -> Void
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("How would you like to start?")
                    .font(HarborFamilyLocationTypography.display)
                Text("Circles are small, private groups you control.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 12)

            Button(action: onCreate) {
                optionRow(
                    symbol: "plus",
                    tint: Color(.calmTeal),
                    title: "Create a circle",
                    subtitle: "Start fresh and invite your family."
                )
            }
            .buttonStyle(.plain)

            Button(action: onJoin) {
                optionRow(
                    symbol: "qrcode",
                    tint: Color(.clearSky),
                    title: "Join a circle",
                    subtitle: "Have an invitation? Enter your code or link."
                )
            }
            .buttonStyle(.plain)

            Spacer()

            Text("You can create or join more circles later.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(Color(uiColor: .systemBackground))
    }

    private func optionRow(
        symbol: String,
        tint: Color,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .harborCard()
    }
}
