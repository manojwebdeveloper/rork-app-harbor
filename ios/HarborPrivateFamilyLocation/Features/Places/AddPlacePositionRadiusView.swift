import SwiftUI

/// Placeholder — steps 2 and 3 of 4: confirm the pin, then size the alert area.
struct AddPlacePositionRadiusView: View {
    @State private var radiusMeters: Double = 150

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(Color(.seaGlass).opacity(0.5))
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(Color(.calmTeal))
            }
            .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Alert area")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(radiusMeters)) meters")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(.calmTeal))
                }

                Text("Drag to resize. You'll get arrival and departure updates when members cross this circle.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(value: $radiusMeters, in: 50...800, step: 25)
                    .tint(Color(.calmTeal))

                NavigationLink("Next") {
                    AddPlaceDetailsView()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundStyle(.white)
                .background(Color(.calmTeal))
                .clipShape(Capsule())
            }
            .padding(20)
            .background(Color(uiColor: .systemBackground))
        }
        .navigationTitle("Position & radius")
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .top)
    }
}
