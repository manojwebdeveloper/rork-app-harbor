import SwiftUI

/// Banner shown on the map the day a travel circle is due to dissolve.
struct TripEndingBanner: View {
    let circleName: String
    /// The circle's real expiry — the same `Date` the circle header's own
    /// "Ends ..." text is built from, so the two can never disagree the way
    /// this banner's old hardcoded "8:00 PM" could.
    let expiresAt: Date
    /// Only the circle's owner can actually extend/keep/end it — the server
    /// already rejects these calls from anyone else with a permission error,
    /// so a non-owner never sees an action they can't use in the first place.
    let isOwner: Bool
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
                    Text("\(circleName) ends \(dayWord)")
                        .font(.system(size: 16, weight: .bold))
                    Text(detailText)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if isOwner {
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
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous)
                .stroke(Color(.warmAmber).opacity(0.45), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 18, y: 6)
    }

    private var dayWord: String {
        if Calendar.current.isDateInToday(expiresAt) { return "today" }
        if Calendar.current.isDateInTomorrow(expiresAt) { return "tomorrow" }
        return "on \(expiresAt.formatted(date: .abbreviated, time: .omitted))"
    }

    private var timeText: String {
        expiresAt.formatted(date: .omitted, time: .shortened)
    }

    private var detailText: String {
        let ending = "At \(timeText) everyone stops sharing and the circle closes."
        guard isOwner else { return ending }
        return "\(ending) Your Activity for this trip is deleted with it."
    }
}
