import SwiftUI

/// Calm Signal type scale. Colour tokens live in `Colors.xcassets` and are used
/// through generated asset symbols, e.g. `Color(.calmTeal)`.
enum HarborFamilyLocationTypography {
    static let display = Font.system(size: 31, weight: .bold, design: .rounded)
    static let title = Font.system(size: 24, weight: .bold, design: .rounded)
    static let headline = Font.headline
    static let body = Font.body
    static let subheadline = Font.subheadline
    static let caption = Font.caption
    static let monoCode = Font.system(size: 34, weight: .bold, design: .monospaced)
}

enum HarborFamilyLocationSpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let standard: CGFloat = 20
    static let section: CGFloat = 28
}

enum HarborFamilyLocationRadius {
    static let field: CGFloat = 16
    static let card: CGFloat = 20
    static let sheet: CGFloat = 30
    static let pill: CGFloat = 999
}

enum HarborFamilyLocationGradient {
    static let brand = LinearGradient(
        colors: [Color(.calmTeal), Color(.clearSky)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
