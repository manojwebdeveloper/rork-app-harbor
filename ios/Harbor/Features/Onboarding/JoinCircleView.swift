import SwiftUI

struct JoinCircleView: View {
    @EnvironmentObject private var circleService: CircleService
    @Environment(\.dismiss) private var dismiss

    @State private var code: String
    @State private var preview: InvitationPreview?
    @State private var isLoading = false
    @State private var errorMessage: String?

    /// Routing hook fired only after an invitation is accepted successfully.
    private let onJoined: ((InvitationPreview) -> Void)?
    /// Called whenever the view closes, accepted or cancelled.
    private let onFinished: () -> Void

    init(
        initialCode: String = "",
        onJoined: ((InvitationPreview) -> Void)? = nil,
        onFinished: @escaping () -> Void = {}
    ) {
        _code = State(initialValue: InvitationLink.normalizedCode(initialCode) ?? initialCode)
        self.onJoined = onJoined
        self.onFinished = onFinished
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Invitation code") {
                    TextField("123456", text: $code)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .font(.system(.title2, design: .monospaced, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .onChange(of: code) { _, newValue in
                            code = String(newValue.filter(\.isNumber).prefix(6))
                            if code.count < 6 {
                                preview = nil
                            }
                        }

                    Button("Check invitation") {
                        Task { await lookup() }
                    }
                    .disabled(code.count != 6 || isLoading)
                }

                if let preview {
                    Section("You’re joining") {
                        LabeledContent("Circle", value: preview.circleName)
                        LabeledContent("Type", value: preview.circleKind.title)
                        LabeledContent(
                            "Invitation expires",
                            value: preview.expiresAt.formatted(date: .abbreviated, time: .shortened)
                        )

                        Button("Join circle") {
                            Task { await accept(preview) }
                        }
                        .fontWeight(.semibold)
                        .disabled(isLoading)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(Color(.signalRed))
                    }
                }
            }
            .navigationTitle("Enter invitation code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onFinished()
                        dismiss()
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Checking code…")
                }
            }
            .task {
                if code.count == 6 {
                    await lookup()
                }
            }
        }
    }

    private func lookup() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            preview = try await circleService.lookupInvitation(code: code)
        } catch {
            preview = nil
            errorMessage = error.localizedDescription
        }
    }

    private func accept(_ preview: InvitationPreview) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await circleService.acceptInvitation(code: preview.code)
            onJoined?(preview)
            onFinished()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
