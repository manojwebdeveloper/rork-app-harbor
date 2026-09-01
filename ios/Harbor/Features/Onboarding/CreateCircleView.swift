import SwiftUI

struct CreateCircleView: View {
    @EnvironmentObject private var circleService: CircleService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var kind: FirebaseCircleSummary.Kind = .family
    @State private var expiresAt = Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    /// Routing hook: receives the new circle id and name. When nil, the view just dismisses.
    private let onCreated: ((String, String) -> Void)?

    init(onCreated: ((String, String) -> Void)? = nil) {
        self.onCreated = onCreated
    }

    var body: some View {
        Form {
            Section("Circle type") {
                Picker("Circle type", selection: $kind) {
                    ForEach(FirebaseCircleSummary.Kind.allCases) { kind in
                        Label(
                            kind.title,
                            systemImage: kind == .family ? "person.3.fill" : "suitcase.rolling.fill"
                        )
                        .tag(kind)
                    }
                }
                .pickerStyle(.inline)
            }

            Section("Details") {
                TextField(kind == .family ? "The Harris Family" : "Paris Weekend", text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                if kind == .trip {
                    DatePicker(
                        "Circle ends",
                        selection: $expiresAt,
                        in: Date.now.addingTimeInterval(3_600)...,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Text("Trip Circle membership and temporary sharing access end automatically at this time.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(Color(.signalRed))
                }
            }
        }
        .navigationTitle("Name your circle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .disabled(isSubmitting)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task { await createCircle() }
                }
                .fontWeight(.semibold)
                .disabled(!isValid || isSubmitting)
            }
        }
        .interactiveDismissDisabled(isSubmitting)
    }

    private var isValid: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    private func createCircle() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let circleID = try await circleService.createCircle(
                name: name,
                kind: kind,
                expiresAt: kind == .trip ? expiresAt : nil
            )

            if let onCreated {
                onCreated(circleID, name.trimmingCharacters(in: .whitespacesAndNewlines))
            } else {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
