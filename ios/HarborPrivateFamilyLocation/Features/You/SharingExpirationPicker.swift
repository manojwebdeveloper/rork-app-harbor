import SwiftUI

/// How long a newly-started sharing session lasts before Harbor asks again.
/// Reused from both the main You screen and Location Sharing, since the
/// brief calls for it in both places.
struct SharingExpirationPicker: View {
    @EnvironmentObject private var userPreferencesService: UserPreferencesService

    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                ForEach(SharingExpirationOption.allCases) { option in
                    Button {
                        save(option)
                    } label: {
                        HStack {
                            Text(option.title)
                                .foregroundStyle(Color.primary)
                            Spacer()
                            if userPreferencesService.sharingExpirationPreference == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color(.calmTeal))
                            }
                        }
                    }
                }
            } footer: {
                Text("When you start sharing with a new circle, this is how long it lasts before Harbor asks you to confirm again.")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color(.signalRed))
                }
            }
        }
        .navigationTitle("Sharing expiration")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save(_ option: SharingExpirationOption) {
        errorMessage = nil
        Task {
            do {
                try await userPreferencesService.updateSharingExpirationPreference(option)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
