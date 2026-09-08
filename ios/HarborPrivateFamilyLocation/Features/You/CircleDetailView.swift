import SwiftUI

/// Per-circle detail: invite, and leave/delete. Pushed from `ManageCirclesView`.
/// No Phase 2 prototype exists for this screen (only the top-level multi-circle
/// list was designed), so per harbor-ios-standards this keeps its existing,
/// already-real layout rather than an improvised redesign.
struct CircleDetailView: View {
    @EnvironmentObject private var circleService: CircleService
    @Environment(\.dismiss) private var dismiss

    let circle: FirebaseCircleSummary

    @State private var showingInvitation = false
    @State private var showingDestructiveConfirmation = false
    @State private var isWorking = false
    @State private var errorMessage: String?

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
        .navigationTitle(circle.name)
        .sheet(isPresented: $showingInvitation) {
            NavigationStack {
                InviteView(circle: circle)
            }
            .environmentObject(circleService)
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
