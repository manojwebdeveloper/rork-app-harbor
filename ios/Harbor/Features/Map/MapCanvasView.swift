import SwiftUI

/// Stylised map backdrop used until the real location engine lands.
/// Draws parks, roads and an optional route so the Phase 2 map layout can be reviewed
/// without MapKit or any real coordinates.
struct MapCanvasView: View {
    let members: [SampleMember]
    let selectedMemberID: String?
    var showsRoute = true
    let onSelectMember: (SampleMember) -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                Color(.mapCanvas)

                parks(in: size)
                roads(in: size)

                if showsRoute, members.count > 1 {
                    route(in: size)
                }

                ForEach(members) { member in
                    Button {
                        onSelectMember(member)
                    } label: {
                        MapPinView(member: member, isSelected: member.id == selectedMemberID)
                    }
                    .buttonStyle(.plain)
                    .position(
                        x: member.mapPoint.x * size.width,
                        y: member.mapPoint.y * size.height
                    )
                }
            }
        }
    }

    private func parks(in size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.mapPark))
                .frame(width: size.width * 0.42, height: size.height * 0.19)
                .position(x: size.width * 0.9, y: size.height * 0.2)

            Circle()
                .fill(Color(.mapPark))
                .frame(width: size.width * 0.86)
                .position(x: size.width * 0.12, y: size.height * 0.94)
        }
    }

    private func roads(in size: CGSize) -> some View {
        ZStack {
            road(from: CGPoint(x: 0.8, y: -0.05), to: CGPoint(x: 0.34, y: 1.05), in: size, width: 22)
            road(from: CGPoint(x: -0.05, y: 0.47), to: CGPoint(x: 1.05, y: 0.53), in: size, width: 14)
            road(from: CGPoint(x: -0.05, y: 0.29), to: CGPoint(x: 1.05, y: 0.17), in: size, width: 9)
            road(from: CGPoint(x: -0.05, y: 0.74), to: CGPoint(x: 1.05, y: 0.84), in: size, width: 9)
        }
    }

    private func road(
        from start: CGPoint,
        to end: CGPoint,
        in size: CGSize,
        width: CGFloat
    ) -> some View {
        Path { path in
            path.move(to: CGPoint(x: start.x * size.width, y: start.y * size.height))
            path.addLine(to: CGPoint(x: end.x * size.width, y: end.y * size.height))
        }
        .stroke(Color(.mapRoad), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    /// A soft travel line between the first two members, matching the design export.
    private func route(in size: CGSize) -> some View {
        let start = members[0].mapPoint
        let end = members[1].mapPoint

        return Path { path in
            path.move(to: CGPoint(x: start.x * size.width, y: (start.y + 0.03) * size.height))
            path.addQuadCurve(
                to: CGPoint(x: end.x * size.width, y: end.y * size.height),
                control: CGPoint(x: (start.x + 0.02) * size.width, y: (end.y - 0.02) * size.height)
            )
        }
        .stroke(
            Color(.clearSky).opacity(0.55),
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
        )
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
