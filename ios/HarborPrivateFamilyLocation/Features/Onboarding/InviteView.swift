import CoreImage.CIFilterBuiltins
import SwiftUI

/// Invitation sharing. The QR generation below is the existing working
/// implementation folded in from the old QRCodeView.
struct InviteView: View {
    @EnvironmentObject private var circleService: CircleService
    @Environment(\.dismiss) private var dismiss

    let circleID: String

    @State private var invitation: InvitationDetails?
    @State private var isLoading = true
    @State private var showingQRCode = true
    @State private var errorMessage: String?

    /// Routing hook for the confirmation button. When nil, the view just dismisses.
    private let onDone: (() -> Void)?

    /// Label for the confirmation button. Onboarding passes "Continue" because the
    /// bar has no back button there — the only action available moves the flow forward.
    private let doneTitle: String

    init(circleID: String, doneTitle: String = "Done", onDone: (() -> Void)? = nil) {
        self.circleID = circleID
        self.doneTitle = doneTitle
        self.onDone = onDone
    }

    init(circle: FirebaseCircleSummary, doneTitle: String = "Done", onDone: (() -> Void)? = nil) {
        self.init(circleID: circle.id, doneTitle: doneTitle, onDone: onDone)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                if let invitation {
                    VStack(spacing: 4) {
                        Text("\(invitation.circleName) is ready")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        Text("Invite your family. Everyone installs HarborPrivateFamilyLocation and chooses to share.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 7) {
                        Text("INVITATION CODE")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(invitation.code)
                            .font(HarborPrivateFamilyLocationTypography.monoCode)
                            .tracking(5)
                        Text("Expires \(invitation.expiresAt.formatted(date: .abbreviated, time: .shortened)) · one circle only")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if showingQRCode {
                        VStack(spacing: 8) {
                            InvitationQRCode(value: invitation.invitationURL.absoluteString)
                            Text("Scan with the camera to join \(invitation.circleName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ShareLink(
                        item: invitation.invitationURL,
                        subject: Text("Join \(invitation.circleName) in HarborPrivateFamilyLocation"),
                        message: Text("Open this link in HarborPrivateFamilyLocation, scan the QR code, or enter code \(invitation.code).")
                    ) {
                        Label("Share invitation link", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .foregroundStyle(.white)
                            .background(Color(.calmTeal))
                            .clipShape(Capsule())
                    }

                    SecondaryButton(title: showingQRCode ? "Hide QR code" : "Show QR code") {
                        withAnimation(.snappy) { showingQRCode.toggle() }
                    }

                    Button("Revoke invitation", role: .destructive) {
                        Task { await revoke(invitation) }
                    }
                } else if isLoading {
                    ProgressView("Creating invitation…")
                        .padding(.top, 80)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color(.signalRed))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
        }
        .navigationTitle("Invite people")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(doneTitle) {
                    if let onDone {
                        onDone()
                    } else {
                        dismiss()
                    }
                }
            }
        }
        .task {
            guard invitation == nil else { return }
            await createInvitation()
        }
    }

    private func createInvitation() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            invitation = try await circleService.createInvitation(circleID: circleID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func revoke(_ invitation: InvitationDetails) async {
        do {
            try await circleService.revokeInvitation(code: invitation.code)

            if let onDone {
                onDone()
            } else {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// Renders an invitation link as a scannable QR code.
struct InvitationQRCode: View {
    let value: String
    var size: CGFloat = 210

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                ContentUnavailableView("QR unavailable", systemImage: "qrcode")
            }
        }
        .frame(width: size, height: size)
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityLabel("Invitation QR code")
    }

    private var image: UIImage? {
        filter.message = Data(value.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }

        let scale = size / output.extent.width
        let transformed = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
