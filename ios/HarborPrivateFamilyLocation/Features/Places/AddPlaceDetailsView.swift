import SwiftUI

struct AddPlaceDetailsView: View {
    let circleID: String
    @State var draft: PlaceDraft
    let onFinished: () -> Void

    @State private var isShowingAlertsStep = false

    var body: some View {
        Form {
            Section {
                TextField("e.g. Pool, Grandma's, Office", text: $draft.name)
                    .textInputAutocapitalization(.words)
            }

            Section("Category") {
                Picker("Category", selection: $draft.category) {
                    ForEach(Place.Category.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.menu)
            }

            if !draft.address.isEmpty {
                Section("Address") {
                    Text(draft.address)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Name this Place")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Next") { isShowingAlertsStep = true }
                    .fontWeight(.semibold)
                    .disabled(trimmedName.isEmpty)
            }
        }
        .navigationDestination(isPresented: $isShowingAlertsStep) {
            PlaceAlertsStepView(circleID: circleID, draft: finalDraft, onFinished: onFinished)
        }
    }

    private var trimmedName: String {
        draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var finalDraft: PlaceDraft {
        var copy = draft
        copy.name = trimmedName.isEmpty ? "this place" : trimmedName
        return copy
    }
}
