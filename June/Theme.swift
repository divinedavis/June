import SwiftUI

extension Color {
    static let juneBackground     = Color(hex: "000000")
    static let juneSurface        = Color(hex: "0D0D0D")
    static let juneSurfaceElevated = Color(hex: "1A1A1A")
    static let juneAccent         = Color(hex: "E8A020")
    static let juneAccentDim      = Color(hex: "E8A020").opacity(0.15)
    static let juneTextPrimary    = Color(hex: "F2F2F2")
    static let juneTextSecondary  = Color(hex: "8A8A8A")
    static let juneTextTertiary   = Color(hex: "555555")
    static let juneBorder         = Color(hex: "2A2A2A")
    static let juneLike           = Color(hex: "E0245E")
    static let juneRepost         = Color(hex: "00BA7C")
    static let juneError          = Color(hex: "FF453A")

    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// Shared corner radius constants
enum JuneRadius {
    static let button: CGFloat = 50
    static let card: CGFloat   = 14
    static let input: CGFloat  = 12
    static let avatar: CGFloat = 22
    static let tag: CGFloat    = 8
}
