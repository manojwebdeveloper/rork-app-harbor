import MapKit
import SwiftUI

struct AddPlacePositionRadiusView: View {
    let circleID: String
    let onFinished: () -> Void

    @State var draft: PlaceDraft
    @State private var cameraPosition: MapCameraPosition

    init(circleID: String, draft: PlaceDraft, onFinished: @escaping () -> Void) {
        self.circleID = circleID
        self._draft = State(initialValue: draft)
        self.onFinished = onFinished
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(center: draft.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Map(position: $cameraPosition) {
                    MapCircle(center: draft.coordinate, radius: draft.radiusMeters)
                        .foregroundStyle(Color(.calmTeal).opacity(0.16))
                        .stroke(Color(.calmTeal), lineWidth: 1.5)
                }

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(Color(.calmTeal))
                    .shadow(radius: 2)
            }
            .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Alert area")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(draft.radiusMeters)) meters")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(.calmTeal))
                }

                Text("Drag to resize. You'll get arrival and departure updates when members cross this circle.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(value: $draft.radiusMeters, in: 50...800, step: 25)
                    .tint(Color(.calmTeal))

                NavigationLink("Next") {
                    AddPlaceDetailsView(circleID: circleID, draft: draft, onFinished: onFinished)
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
