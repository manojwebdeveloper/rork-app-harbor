import SwiftUI

/// Placeholder — layout only. Saved places arrive with the location engine.
struct PlacesView: View {
    @State private var isAddingPlace = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Know when the people you care about arrive or leave.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous)
                        .fill(Color(.seaGlass).opacity(0.5))
                        .frame(height: 96)
                        .overlay {
                            Image(systemName: "map")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(Color(.calmTeal))
                        }

                    ContentUnavailableView {
                        Label("No places yet", systemImage: "mappin.and.ellipse")
                    } description: {
                        Text("Add a place to get arrival and departure updates for the people in your circle.")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .harborCard()

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
                }
            }
            .sheet(isPresented: $isAddingPlace) {
                NavigationStack {
                    AddPlaceSearchView()
                }
            }
        }
    }
}
