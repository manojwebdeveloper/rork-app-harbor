import SwiftUI

struct MemberMarker: View {
    let member: HarborFamilyLocationMember
    var size: CGFloat = 48
    var isSelected = false

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(member.tint.opacity(0.18))
                    .frame(width: size + 18, height: size + 18)
            }

            Circle()
                .fill(member.tint)
                .frame(width: size, height: size)
                .overlay {
                    Circle()
                        .fill(member.tint.opacity(0.16))
                        .padding(4)
                        .overlay {
                            Text(member.initials)
                                .font(.system(size: size * 0.34, weight: .semibold))
                                .foregroundStyle(member.tint)
                        }
                }
                .overlay { Circle().stroke(.white, lineWidth: 3) }

            Circle()
                .fill(statusColor)
                .frame(width: size * 0.28, height: size * 0.28)
                .overlay { Circle().stroke(.white, lineWidth: 2) }
                .offset(x: size * 0.36, y: -size * 0.36)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(member.name), \(member.presence.rawValue)")
    }

    private var statusColor: Color {
        switch member.presence {
        case .live, .recent, .arrived: Color(.safeGreen)
        case .travelling: Color(.clearSky)
        case .delayed: Color(.warmAmber)
        case .offline, .paused: Color(.slate)
        }
    }
}
