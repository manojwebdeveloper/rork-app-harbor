import SwiftUI

/// Final step of the Add Place flow: everyday alerts plus the Smart Alerts entry point.
struct PlaceAlertsStepView: View {
    let placeName: String
    let placeAddress: String
    let onSave: () -> Void

    @State private var arrivalAlertsEnabled = true
    @State private var departureAlertsEnabled = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Everyday alerts cover arrivals and departures. Smart Alerts add the ones that depend on time.")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            VStack(spacing: 0) {
                Toggle("Arrival alerts", isOn: $arrivalAlertsEnabled)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                Divider().padding(.leading, 16)

                Toggle("Departure alerts", isOn: $departureAlertsEnabled)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .font(.system(size: 16))
            .tint(Color(.safeGreen))
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.field, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.field, style: .continuous)
                    .stroke(Color(.mineralBorder).opacity(0.8), lineWidth: 0.5)
            }
            .padding(.top, 20)

            NavigationLink {
                SmartAlertsListView(placeName: placeName, placeAddress: placeAddress)
            } label: {
                HStack(spacing: 13) {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Color(.seaGlass))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: "clock")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(.calmTeal))
                        }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Smart Alerts")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.primary)
                        Text("\(HarborPrivateFamilyLocationSample.smartAlertRules.count) of \(HarborPrivateFamilyLocationSample.smartAlertRules.count) rules on")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.field, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.field, style: .continuous)
                        .stroke(Color(.mineralBorder).opacity(0.8), lineWidth: 0.5)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 14)

            Spacer()

            stepDots
                .padding(.bottom, 18)

            PrimaryButton(title: "Save Place", action: onSave)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 20)
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("Alerts for \(placeName)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var stepDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(index == 3 ? Color(.calmTeal) : Color(.mineralBorder))
                    .frame(width: index == 3 ? 18 : 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
