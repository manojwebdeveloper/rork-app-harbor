import SwiftUI

/// Banner shown on the map the day a travel circle is due to dissolve.
/// Layout only — no expiry timer runs behind it.
struct TripEndingBanner: View {
    let circleName: String
    let onExtend: () -> Void
    let onKeepPermanently: () -> Void
    let onLetItEnd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 13) {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color(.warmAmber).opacity(0.16))
                    .frame(width: 38, height: 38)
                    .overlay {
                        Image(systemName: "clock")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(.warmAmber))
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(circleName) ends tomorrow")
                        .font(.system(size: 16, weight: .bold))
                    Text("At 8:00 PM everyone stops sharing and the circle closes. Your Activity for this trip is deleted with it.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 12) {
                Button(action: onExtend) {
                    Text("Extend 3 days")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(.calmTeal))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button(action: onKeepPermanently) {
                    Text("Keep permanently")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(.calmTeal))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(uiColor: .systemBackground))
                        .clipShape(Capsule())
                        .overlay { Capsule().stroke(Color(.calmTeal), lineWidth: 1.5) }
                }
                .buttonStyle(.plain)
            }

            Button(action: onLetItEnd) {
                Text("Let it end")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: HarborRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: HarborRadius.card, style: .continuous)
                .stroke(Color(.warmAmber).opacity(0.45), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 18, y: 6)
    }
}
