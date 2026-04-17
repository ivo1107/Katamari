import SwiftUI

enum KatamariTheme {
    enum Colors {
        static let primary         = Color("PrimaryColor",       bundle: .main)
        static let secondary       = Color("SecondaryColor",     bundle: .main)
        static let accent          = Color("AccentColor",        bundle: .main)
        static let background      = Color("BackgroundColor",    bundle: .main)
        static let cardBackground  = Color("CardBackground",     bundle: .main)
        static let label           = Color("LabelColor",         bundle: .main)
        static let secondaryLabel  = Color("SecondaryLabel",     bundle: .main)
        static let separator       = Color("SeparatorColor",     bundle: .main)

        // Fallbacks for when asset catalog isn't set up
        static var primaryFallback:    Color { Color(red: 0.33, green: 0.33, blue: 0.96) }
        static var secondaryFallback:  Color { Color(red: 0.55, green: 0.25, blue: 0.96) }
        static var accentFallback:     Color { Color(red: 1.0,  green: 0.58, blue: 0.0)  }
    }

    enum Typography {
        static var largeTitle: Font { .system(size: 34, weight: .black, design: .rounded) }
        static var title:      Font { .system(size: 28, weight: .bold,  design: .rounded) }
        static var headline:   Font { .system(size: 17, weight: .semibold) }
        static var body:       Font { .system(size: 17, weight: .regular) }
        static var caption:    Font { .system(size: 12, weight: .medium) }
    }

    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum CornerRadius {
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 12
        static let lg:  CGFloat = 16
        static let xl:  CGFloat = 24
        static let pill: CGFloat = 999
    }
}
