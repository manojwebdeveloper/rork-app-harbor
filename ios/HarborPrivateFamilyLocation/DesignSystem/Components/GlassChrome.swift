import SwiftUI

/// Liquid Glass helpers for the app's navigation/control chrome — the
/// custom tab bar, floating map controls, sheet dismiss buttons and action
/// rows. These wrap the real iOS 26 `.glassEffect()`/`GlassEffectContainer`
/// APIs (which already respect Reduce Transparency and Reduce Motion
/// internally) with a pre-26 fallback that reproduces this app's previous
/// flat/material chrome unchanged, since the deployment target is iOS 18.
///
/// Chrome only. Never apply these to content — list rows, cards, the map
/// surface, or full-screen/sheet backgrounds — text must always sit on a
/// solid layer, not directly on glass. See harbor-ios-standards.
///
/// Don't reach for `harborGlass(in:)` inside a real system `ToolbarItem`,
/// `NavigationStack` bar, `.sheet` presentation chrome, or anything else
/// UIKit/SwiftUI already renders for you — iOS 26 wraps those in genuine
/// Liquid Glass automatically, and a second manual `.glassEffect()` on top
/// conflicts with it (in one case it silently hid a toolbar button's label).
/// These helpers are only for views this app draws itself.
extension View {
    /// Applies real Liquid Glass to a control surface on iOS 26+, or the
    /// given `fallback` style (a solid color or a system material) on
    /// earlier OS versions.
    @ViewBuilder
    func harborGlass<S: Shape, F: ShapeStyle>(
        in shape: S,
        tint: Color? = nil,
        interactive: Bool = true,
        fallback: F
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(harborResolvedGlass(tint: tint, interactive: interactive), in: shape)
        } else {
            self
                .background(fallback)
                .clipShape(shape)
        }
    }
}

@available(iOS 26.0, *)
private func harborResolvedGlass(tint: Color?, interactive: Bool) -> Glass {
    var glass = Glass.regular
    if let tint {
        glass = glass.tint(tint)
    }
    if interactive {
        glass = glass.interactive()
    }
    return glass
}

/// Groups adjacent glass surfaces (a control stack, an action row) so the
/// real API can morph/merge them as they approach each other on iOS 26+.
/// A plain pass-through pre-26, where no such grouping exists.
struct HarborGlassGroup<Content: View>: View {
    var spacing: CGFloat?
    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}

/// The circular glass "✕" dismiss control used throughout sheets and cards.
/// Liquid Glass on iOS 26+; a flat secondary-fill circle (this app's
/// previous look) pre-26.
struct GlassDismissButton: View {
    let action: () -> Void
    var size: CGFloat = 32

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: size, height: size)
                .harborGlass(in: Circle(), fallback: Color(uiColor: .secondarySystemFill))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }
}
