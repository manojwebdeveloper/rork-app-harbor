import Combine
import CoreLocation
import MapKit
import SwiftUI

/// In-progress state for the 4-step Add Place flow. Nothing is written to
/// Firestore until `AddPlaceDetailsView` hands off to `PlaceAlertsStepView`,
/// which creates the place so its Smart Alerts entry point has a real place
/// to attach rules to.
struct PlaceDraft {
    var name = ""
    var address = ""
    var category: Place.Category = .custom
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var radiusMeters: Double = 150
}

struct AddPlaceSearchView: View {
    let circleID: String
    let onFinished: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var completerDelegate = LocalSearchCompleterDelegate()
    @State private var query = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search or drop a pin on the map", text: $query)
                    .onChange(of: query) { _, newValue in
                        completerDelegate.completer.queryFragment = newValue
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.field, style: .continuous))

            if query.isEmpty {
                Text("SUGGESTED")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    suggestion("Work") { query = "Work" }
                    suggestion("Current location", action: useCurrentLocation)
                }
            }

            List(completerDelegate.results, id: \.self) { result in
                Button {
                    resolve(result)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.title)
                            .foregroundStyle(Color.primary)
                        if !result.subtitle.isEmpty {
                            Text(result.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.plain)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color(.signalRed))
            }
        }
        .padding(20)
        .navigationTitle("Add a Place")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .navigationDestination(isPresented: $isShowingPosition) {
            if let draft {
                AddPlacePositionRadiusView(circleID: circleID, draft: draft, onFinished: onFinished)
            }
        }
        .overlay {
            if isResolving {
                ProgressView()
            }
        }
    }

    @State private var draft: PlaceDraft?
    @State private var isShowingPosition = false
    @State private var isResolving = false
    @State private var errorMessage: String?

    private func suggestion(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func resolve(_ completion: MKLocalSearchCompletion) {
        isResolving = true
        errorMessage = nil
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { response, error in
            Task { @MainActor in
                isResolving = false
                guard let item = response?.mapItems.first else {
                    errorMessage = error?.localizedDescription ?? "Couldn't find that place. Try a different search."
                    return
                }
                var newDraft = PlaceDraft()
                newDraft.name = item.name ?? completion.title
                newDraft.address = Self.formattedAddress(for: item)
                newDraft.coordinate = item.placemark.coordinate
                draft = newDraft
                isShowingPosition = true
            }
        }
    }

    private func useCurrentLocation() {
        guard let coordinate = CLLocationManager().location?.coordinate else {
            errorMessage = "Your current location isn't available yet."
            return
        }
        var newDraft = PlaceDraft()
        newDraft.coordinate = coordinate
        newDraft.address = "Current location"
        draft = newDraft
        isShowingPosition = true
    }

    private static func formattedAddress(for item: MKMapItem) -> String {
        let placemark = item.placemark
        let parts = [placemark.thoroughfare, placemark.locality, placemark.administrativeArea]
            .compactMap { $0 }
        return parts.isEmpty ? (item.name ?? "") : parts.joined(separator: ", ")
    }
}

@MainActor
private final class LocalSearchCompleterDelegate: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in self.results = completer.results }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in self.results = [] }
    }
}
