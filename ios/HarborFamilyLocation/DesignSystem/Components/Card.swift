import SwiftUI

struct CardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(colorScheme == .dark ? Color(.deepSlate) : .white)
            .clipShape(RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.card, style: .continuous)
                    .stroke(Color(.mineralBorder).opacity(0.8), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.24 : 0.07), radius: 16, y: 4)
    }
}

extension View {
    func harborCard() -> some View {
        modifier(CardModifier())
    }
}
