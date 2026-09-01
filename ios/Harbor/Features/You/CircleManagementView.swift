import SwiftUI

struct CircleManagementView: View {
    @EnvironmentObject private var circleService: CircleService

    @State private var showingCreate = false
    @State private var showingJoin = false

    var body: some View {
        List {
            if circleService.circles.isEmpty && !circleService.isLoading {
                Section {
                    ContentUnavailableView {
                        Label("No circles yet", systemImage: "person.3")
                    } description: {
                        Text("Create a family or trip circle, or join someone you trust with an invitation code.")
                    } actions: {
                        Button("Create circle") { showingCreate = true }
                            .buttonStyle(.borderedProminent)
                        Button("Join circle") { showingJoin = true }
                            .buttonStyle(.bordered)
                    }
                }
            } else {
                Section("Members · colours by join order") {
                    ForEach(circleService.circles) { circle in
                        NavigationLink {
                            CircleDetailView(circle: circle)
                        } label: {
                            circleRow(circle)
                        }
                    }
                }
            }

            if let errorMessage = circleService.errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color(.signalRed))
                }
            }
        }
        .navigationTitle("Your circles")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Create circle", systemImage: "plus.circle") {
                        showingCreate = true
                    }
                    Button("Join with code", systemImage: "number.square") {
                        showingJoin = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if circleService.isLoading {
                ProgressView()
            }
        }
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                CreateCircleView()
            }
            .environmentObject(circleService)
        }
        .sheet(isPresented: $showingJoin) {
            JoinCircleView()
                .environmentObject(circleService)
        }
    }

    private func circleRow(_ circle: FirebaseCircleSummary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: circle.kind == .family ? "person.3.fill" : "suitcase.rolling.fill")
                .foregroundStyle(circle.kind == .family ? Color(.calmTeal) : Color(.clearSky))
                .frame(width: 34, height: 34)
                .background(
                    circle.kind == .family
                        ? Color(.seaGlass)
                        : Color(.clearSky).opacity(0.14)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(circle.name)
                    .font(.headline)
                HStack(spacing: 6) {
                    Text(circle.kind.title)
                    Text("•")
                    Text(circle.role.capitalized)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if let expiresAt = circle.expiresAt {
                Text(expiresAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CircleDetailView: View {
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
