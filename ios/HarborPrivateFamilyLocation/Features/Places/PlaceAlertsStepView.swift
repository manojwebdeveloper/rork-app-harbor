import SwiftUI

/// Final step of the Add Place flow. Creates the place in Firestore as soon
/// as this screen appears — Smart Alerts needs a real place to attach rules
/// to, and the toggles below update that same place live rather than being
/// held in local state until a final "Save".
struct PlaceAlertsStepView: View {
    let circleID: String
    let draft: PlaceDraft
    let onFinished: () -> Void

    @EnvironmentObject private var placesService: PlacesService

    @State private var placeID: String?
    @State private var arrivalAlertsEnabled = true
    @State private var departureAlertsEnabled = true
    @State private var isSaving = true
    @State private var errorMessage: String?

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
                    .onChange(of: arrivalAlertsEnabled) { _, _ in persistToggles() }

                Divider().padding(.leading, 16)

                Toggle("Departure alerts", isOn: $departureAlertsEnabled)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .onChange(of: departureAlertsEnabled) { _, _ in persistToggles() }
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
            .disabled(placeID == nil)

            if let placeID {
                NavigationLink {
                    SmartAlertsListView(circleID: circleID, placeID: placeID, placeName: draft.name, placeAddress: draft.address)
                } label: {
                    smartAlertsRow
                }
                .buttonStyle(.plain)
                .padding(.top, 14)
            } else {
                smartAlertsRow
                    .opacity(0.5)
                    .padding(.top, 14)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color(.signalRed))
                    .padding(.top, 10)
            }

            Spacer()

            stepDots
                .padding(.bottom, 18)

            PrimaryButton(title: "Save Place", action: onFinished)
                .padding(.bottom, 12)
                .disabled(placeID == nil)
        }
        .padding(.horizontal, 20)
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("Alerts for \(draft.name)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await createPlace()
        }
    }

    private var smartAlertsRow: some View {
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
                Text(placeID == nil ? "Saving place…" : "Add a rule")
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

    private func createPlace() async {
        isSaving = true
        errorMessage = nil
        do {
            let id = try await placesService.addPlace(
                circleID: circleID,
                name: draft.name,
                address: draft.address,
                category: draft.category,
                coordinate: draft.coordinate,
                radiusMeters: draft.radiusMeters,
                arrivalAlertsEnabled: arrivalAlertsEnabled,
                departureAlertsEnabled: departureAlertsEnabled
            )
            placeID = id
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func persistToggles() {
        guard let placeID else { return }
        Task {
            do {
                try await placesService.setPlaceAlerts(
                    circleID: circleID,
                    placeID: placeID,
                    arrivalAlertsEnabled: arrivalAlertsEnabled,
                    departureAlertsEnabled: departureAlertsEnabled
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
