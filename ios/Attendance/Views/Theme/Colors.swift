import SwiftUI

public extension Color {
    // Brand Indigo Palette
    static let brandIndigo = Color(hex: 0x4F46E5)
    static let brandIndigoDark = Color(hex: 0x3730A3)
    static let brandIndigoLight = Color(hex: 0xEEF2FF)

    static let primaryBlue = Color(hex: 0x4F46E5)
    static let primaryDark = Color(hex: 0x3730A3)
    static let primaryLight = Color(hex: 0xEEF2FF)

    // Neutral Slates
    static let slateDark = Color(hex: 0x0F172A)
    static let slateMedium = Color(hex: 0x64748B)
    static let slateLight = Color(hex: 0x94A3B8)
    static let borderLight = Color(hex: 0xE2E8F0)
    static let borderSubtle = Color(hex: 0xF1F5F9)
    static let lightBackground = Color(hex: 0xF8FAFC)

    // Emerald Palette (Success / Check-in)
    static let emeraldPrimary = Color(hex: 0x059669)
    static let emeraldDark = Color(hex: 0x047857)
    static let emeraldBg = Color(hex: 0xECFDF5)
    static let emeraldBorder = Color(hex: 0xA7F3D0)

    // Rose Palette (Destructive / Check-out)
    static let rosePrimary = Color(hex: 0xE11D48)
    static let roseDark = Color(hex: 0xBE123C)
    static let roseBg = Color(hex: 0xFFF1F2)
    static let roseBorder = Color(hex: 0xFECDD3)

    // Amber Palette (Warning / Pending / Holidays)
    static let amberPrimary = Color(hex: 0xD97706)
    static let amberDark = Color(hex: 0x92400E)
    static let amberBg = Color(hex: 0xFFFBEB)
    static let amberBorder = Color(hex: 0xFDE68A)

    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

public extension LinearGradient {
    static let punchInGradient = LinearGradient(
        colors: [Color(hex: 0x059669), Color(hex: 0x10B981)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let punchOutGradient = LinearGradient(
        colors: [Color(hex: 0xE11D48), Color(hex: 0xF43F5E)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let premiumIndigoGradient = LinearGradient(
        colors: [Color(hex: 0x4F46E5), Color(hex: 0x6366F1), Color(hex: 0x7C3AED)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

