import SwiftUI

/// Placeholder — step 1 of 4. Search wiring arrives with MapKit local search.
struct AddPlaceSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search or drop a pin on the map", text: $query)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.field, style: .continuous))

            Text("SUGGESTED")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                suggestion("Work")
                suggestion("Grandparents")
                suggestion("Current location")
            }

            Spacer()

            NavigationLink("Continue") {
                AddPlacePositionRadiusView()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(.white)
            .background(Color(.calmTeal))
            .clipShape(Capsule())
        }
        .padding(20)
        .navigationTitle("Add a Place")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func suggestion(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(Capsule())
    }
}
