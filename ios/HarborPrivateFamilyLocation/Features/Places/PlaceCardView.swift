import SwiftUI

/// Placeholder — layout only. One saved place row on the Places tab.
struct PlaceCardView: View {
    let place: Place

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(.calmTeal))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(.headline)
                    Text(place.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                Text("No one here right now")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(alertSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .harborCard()
    }

    private var alertSummary: String {
        switch (place.arrivalAlertsEnabled, place.departureAlertsEnabled) {
        case (true, true): "Arrive & leave alerts on"
        case (true, false): "Arrival alerts on"
        case (false, true): "Departure alerts on"
        case (false, false): "Alerts off"
        }
    }
}
