import SwiftUI

struct MemberCarouselView: View {
    let members: [FirebaseCircleMember]
    let selectedMemberID: String?
    let onSelect: (FirebaseCircleMember) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Circle members")
                .font(.title3.bold())

            if members.isEmpty {
                ContentUnavailableView(
                    "No members yet",
                    systemImage: "person.badge.plus",
                    description: Text("Create and share an invitation from circle management.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .harborCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                        Button {
                            onSelect(member)
                        } label: {
                            memberRow(member)
                        }
                        .buttonStyle(.plain)

                        if index < members.count - 1 {
                            Divider().padding(.leading, 54)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: HarborRadius.card, style: .continuous))
            }
        }
    }

    private func memberRow(_ member: FirebaseCircleMember) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.seaGlass))
                .frame(width: 42, height: 42)
                .overlay {
                    Text(initials(for: member.displayName))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(.calmTeal))
                }
                .overlay {
                    if member.id == selectedMemberID {
                        Circle().stroke(Color(.calmTeal), lineWidth: 2)
                    }
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(member.displayName)
                    .font(.headline)
                Text(member.role.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StatusBadge(
                text: member.sharingEnabled ? "Sharing" : "Sharing off",
                color: member.sharingEnabled ? Color(.safeGreen) : Color(.slate)
            )
        }
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }

    private func initials(for name: String) -> String {
        let characters = name.split(separator: " ").prefix(2).compactMap(\.first)
        let value = String(characters)
        return value.isEmpty ? "H" : value.uppercased()
    }
}
