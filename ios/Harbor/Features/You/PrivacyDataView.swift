import SwiftUI

/// Placeholder — layout only, except the account deletion link which is live.
struct PrivacyDataView: View {
    var body: some View {
        List {
            Section("Who can see you") {
                LabeledContent("Circle memberships", value: "Firebase")
                LabeledContent("Location sharing", value: "Not connected")
            }

            Section("Your location history") {
                LabeledContent("How long we keep it", value: "No data collected")
                Button("Delete location history now") { }
                    .disabled(true)
            }

            Section("Your account") {
                Button("Export a copy of your data") { }
                    .disabled(true)

                NavigationLink {
                    DeleteAccountView()
                } label: {
                    Text("Delete account")
                        .foregroundStyle(Color(.signalRed))
                }
            }
        }
        .navigationTitle("Privacy & data")
        .navigationBarTitleDisplayMode(.inline)
    }
}
