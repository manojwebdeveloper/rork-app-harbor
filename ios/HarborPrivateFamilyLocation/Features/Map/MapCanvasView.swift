import MapKit
import SwiftUI

/// Real MapKit map with member pins at their live coordinates. Replaced the
/// original hand-drawn Phase 2 canvas, which positioned members with an
/// arbitrary unit-square `mapPoint` that had no relationship to a real
/// latitude/longitude and so couldn't display genuine location data.
struct MapCanvasView: View {
    let members: [SampleMember]
    let selectedMemberID: String?
    var showsRoute = true
    let onSelectMember: (SampleMember) -> Void

    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {
            if showsRoute, members.count > 1 {
                MapPolyline(coordinates: members.map(\.coordinate))
                    .stroke(Color(.clearSky).opacity(0.55), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }

            ForEach(members) { member in
                Annotation(member.name, coordinate: member.coordinate, anchor: .bottom) {
                    Button {
                        onSelectMember(member)
                    } label: {
                        MapPinView(member: member, isSelected: member.id == selectedMemberID)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear { focusCamera() }
        .onChange(of: members.map(\.id)) { _, _ in focusCamera() }
    }

    private func focusCamera() {
        guard !members.isEmpty else { return }

        if members.count == 1, let coordinate = members.first?.coordinate {
            cameraPosition = .region(
                MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
            )
            return
        }

        let mapRect = members.reduce(MKMapRect.null) { partial, member in
            partial.union(MKMapRect(origin: MKMapPoint(member.coordinate), size: MKMapSize(width: 0, height: 0)))
        }
        cameraPosition = .rect(mapRect.insetBy(dx: -mapRect.width * 0.4, dy: -mapRect.height * 0.4))
    }
}

/// A single member pin: initials in a tinted ring, a status badge, and a pointer.
struct MapPinView: View {
    let member: SampleMember
    var isSelected = false

    var body: some View {
        VStack(spacing: -5) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(member.tint.color.opacity(0.16))
                        .frame(width: 92, height: 92)
                }

                Circle()
                    .fill(Color(uiColor: .systemBackground))
                    .frame(width: 50, height: 50)
                    .overlay { Circle().stroke(member.tint.color, lineWidth: 2.5) }
                    .overlay {
                        Text(member.initials)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(member.tint.color)
                    }
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 3)

                badge
                    .offset(x: 19, y: -19)
            }

            PinPointer()
                .fill(member.tint.color)
                .frame(width: 13, height: 10)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(member.name), \(member.statusDetail)")
    }

    @ViewBuilder
    private var badge: some View {
        if member.isDriving {
            statusGlyph(symbol: "car.fill", tint: Color(.clearSky))
        } else if member.isBatteryLow {
            statusGlyph(symbol: "battery.25percent", tint: Color(.warmAmber))
        } else {
            Circle()
                .fill(member.presence.color)
                .frame(width: 14, height: 14)
                .overlay { Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2) }
        }
    }

    private func statusGlyph(symbol: String, tint: Color) -> some View {
        Circle()
            .fill(tint)
            .frame(width: 22, height: 22)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay { Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2) }
    }
}

private struct PinPointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
