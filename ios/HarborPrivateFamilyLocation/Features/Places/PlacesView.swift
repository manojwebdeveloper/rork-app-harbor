import SwiftUI

struct PlacesView: View {
    @EnvironmentObject private var circleService: CircleService
    @EnvironmentObject private var placesService: PlacesService

    @State private var isAddingPlace = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Know when the people you care about arrive or leave.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color(.signalRed))
                    }

                    if placesService.places.isEmpty {
                        ContentUnavailableView {
                            Label("No places yet", systemImage: "mappin.and.ellipse")
                        } description: {
                            Text("Add a place to get arrival and departure updates for the people in your circle.")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .harborCard()
                    } else {
                        ForEach(placesService.places) { place in
                            PlaceCardView(place: place) {
                                delete(place)
                            }
                        }
                    }

                    Text("Places you save here are private to your circle.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 130)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Places")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingPlace = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(circleService.selectedCircleID == nil)
                }
            }
            .sheet(isPresented: $isAddingPlace) {
                if let circleID = circleService.selectedCircleID {
                    NavigationStack {
                        AddPlaceSearchView(circleID: circleID) {
                            isAddingPlace = false
                        }
                    }
                }
            }
        }
    }

    private func delete(_ place: Place) {
        guard let circleID = circleService.selectedCircleID else { return }
        Task {
            do {
                try await placesService.deletePlace(circleID: circleID, placeID: place.id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
