import SwiftUI

/// Per-circle detail: members, invite, rename, and leave/delete. Pushed
/// from `ManageCirclesView`. No Phase 2 prototype exists for this exact
/// screen (only the top-level multi-circle list was designed), so per
/// harbor-ios-standards this keeps its existing, already-real layout
/// rather than an improvised redesign.
struct CircleDetailView: View {
    @EnvironmentObject private var circleService: CircleService
    @Environment(\.dismiss) private var dismiss

    let circle: FirebaseCircleSummary

    @State private var members: [FirebaseCircleMember] = []
    @State private var editableName: String
    @State private var showingInvitation = false
    @State private var showingDestructiveConfirmation = false
    @State private var showingRename = false
    @State private var renameDraft = ""
    @State private var isWorking = false
    @State private var errorMessage: String?

    init(circle: FirebaseCircleSummary) {
        self.circle = circle
        _editableName = State(initialValue: circle.name)
    }

    private var canManage: Bool {
        circle.role == "owner" || circle.role == "admin"
    }

    var body: some View {
        List {
            Section("Circle") {
                LabeledContent("Type", value: circle.kind.title)
                LabeledContent("Your role", value: circle.role.capitalized)
                if let expiresAt = circle.expiresAt {
                    LabeledContent(
                        "Ends",
                        value: expiresAt.formatted(date: .abbreviated, time: .shortened)
                    )
                }
                if canManage {
                    Button("Rename circle") {
                        renameDraft = editableName
                        showingRename = true
                    }
                }
            }

            Section("Members · colours by join order") {
                if members.isEmpty {
                    Text("Loading members…")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(members) { member in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.displayName)
                                Text(member.role.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(member.sharingEnabled ? "Sharing" : "Paused")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(member.sharingEnabled ? Color(.safeGreen) : Color(.slate))
                        }
                    }
                }
            }

            Section("Invite people") {
                Button {
                    showingInvitation = true
                } label: {
                    Label("Invite family member", systemImage: "person.badge.plus")
                }
            }

            Section {
                Button(
                    circle.role == "owner" ? "Delete circle" : "Leave circle",
                    role: .destructive
                ) {
                    showingDestructiveConfirmation = true
                }
                .disabled(isWorking)
            } footer: {
                Text(circle.role == "owner"
                     ? "Deleting this circle removes all memberships and active invitations."
                     : "Leaving immediately removes your access to this circle.")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(Color(.signalRed))
                }
            }
        }
        .navigationTitle(editableName)
        .task {
            members = (try? await circleService.fetchMembers(circleID: circle.id)) ?? []
        }
        .sheet(isPresented: $showingInvitation) {
            NavigationStack {
                InviteView(circle: circle)
            }
            .environmentObject(circleService)
        }
        .alert("Rename circle", isPresented: $showingRename) {
            TextField("Circle name", text: $renameDraft)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                Task { await rename() }
            }
        }
        .confirmationDialog(
            circle.role == "owner" ? "Delete this circle?" : "Leave this circle?",
            isPresented: $showingDestructiveConfirmation,
            titleVisibility: .visible
        ) {
            Button(circle.role == "owner" ? "Delete circle" : "Leave circle", role: .destructive) {
                Task { await performDestructiveAction() }
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func rename() async {
        let trimmed = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            try await circleService.renameCircle(circleID: circle.id, name: trimmed)
            editableName = trimmed
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func performDestructiveAction() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            if circle.role == "owner" {
                try await circleService.deleteCircle(circleID: circle.id)
            } else {
                try await circleService.leaveCircle(circleID: circle.id)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
