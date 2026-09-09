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

    // Falls back to the device's own GPS position (native blue dot, via
    // UserAnnotation below) when no circle member — including the current
    // user — has a published RTDB coordinate yet, instead of sitting on a
    // wide, meaningless default region. This needs location permission
    // already granted; if it isn't, MapKit just shows nothing extra and
    // .automatic takes over, so it's always safe to set.
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    // Whether the map rotates to match the device's compass heading — the
    // "heading-up" mode the design's compass button implies, versus the
    // default fixed north-up orientation.
    @State private var followsHeading = false
    @State private var mapStyleOption: MapStyleOption = .standard

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

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
        .mapStyle(mapStyleOption.mapStyle)
        .onAppear { focusCamera() }
        .onChange(of: members.map(\.id)) { _, _ in focusCamera() }
        .overlay(alignment: .topTrailing) {
            mapControlStack
                .padding(.top, 130)
                .padding(.trailing, 16)
        }
    }

    private var mapControlStack: some View {
        VStack(spacing: 10) {
            MapControlButton(symbol: "scope", isActive: false, accessibilityLabel: "Recenter on my location") {
                recenterOnSelf()
            }
            MapControlButton(symbol: "location.north.line.fill", isActive: followsHeading, accessibilityLabel: "Toggle heading-up orientation") {
                toggleHeading()
            }
            MapControlButton(symbol: "square.3.layers.3d", isActive: mapStyleOption != .standard, accessibilityLabel: "Change map layers") {
                cycleMapStyle()
            }
        }
    }

    /// Snaps back to the current user's own live coordinate — distinct from
    /// `focusCamera()`, which frames *every* pinned member and is only ever
    /// called automatically when the member set changes.
    private func recenterOnSelf() {
        withAnimation {
            if let selfMember = members.first(where: \.isSelf) {
                cameraPosition = .region(
                    MKCoordinateRegion(center: selfMember.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
                )
            } else {
                cameraPosition = .userLocation(followsHeading: followsHeading, fallback: .automatic)
            }
        }
    }

    private func toggleHeading() {
        followsHeading.toggle()
        withAnimation {
            cameraPosition = .userLocation(followsHeading: followsHeading, fallback: .automatic)
        }
    }

    private func cycleMapStyle() {
        mapStyleOption = mapStyleOption.next
    }

    private func focusCamera() {
        // Nobody has published a coordinate yet — stay on .userLocation
        // (the device's own GPS fix) rather than snapping back to .automatic.
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

/// The map's layers control cycles through these — standard street map,
/// satellite+labels, and pure satellite imagery. The design's icon (stacked
/// squares) implies a general "switch map layers" affordance without
/// specifying which layers, so this picks the three built-in MapKit styles.
private enum MapStyleOption: CaseIterable {
    case standard, hybrid, imagery

    var mapStyle: MapStyle {
        switch self {
        case .standard: .standard
        case .hybrid: .hybrid
        case .imagery: .imagery
        }
    }

    var next: MapStyleOption {
        let all = Self.allCases
        let index = all.firstIndex(of: self) ?? 0
        return all[(index + 1) % all.count]
    }
}

/// One rounded-square control button, matching the design's right-side map
/// control stack (recenter, heading, layers).
private struct MapControlButton: View {
    let symbol: String
    let isActive: Bool
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isActive ? Color(.calmTeal) : Color.primary)
                .frame(width: 44, height: 44)
                .background(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

/// A single member pin: initials in a tinted ring, a status badge, and a pointer.
struct MapPinView: View {
    let member: SampleMember
    var isSelected = false

    var body: some View {
        VStack(spacing: -5) {
            ZStack {
                if member.isSelf {
                    // A persistent highlight, not just a selection state —
                    // this is what makes the self pin readable as "you" at a
                    // glance, the way Life360/Find My distinguish their own
                    // marker from everyone else's.
                    Circle()
                        .stroke(Color(.calmTeal), lineWidth: 2)
                        .frame(width: 66, height: 66)
                }

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
