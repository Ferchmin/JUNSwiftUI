import SwiftUI

/// Parses JUN color strings.
///
/// Namespaced rather than added to `Color` so that nothing here collides with the hex
/// initialiser most host applications already define.
enum JUNColor {

    /// Returns the color for a JUN color string, or `nil` if it names nothing recognisable.
    static func parse(_ colorString: String) -> Color? {
        switch colorString.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "gray", "grey": return .gray
        case "black": return .black
        case "white": return .white
        case "primary": return .primary
        case "secondary": return .secondary
        default: return hex(colorString)
        }
    }

    /// Parses `#RRGGBB` and `#RRGGBBAA`. Shorthand `#RGB` is not part of the format.
    static func hex(_ value: String) -> Color? {
        var sanitized: String = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard sanitized.hasPrefix("#") else { return nil }
        sanitized.removeFirst()

        guard sanitized.allSatisfy(\.isHexDigit) else { return nil }

        var rgb: UInt64 = 0
        guard Scanner(string: sanitized).scanHexInt64(&rgb) else { return nil }

        switch sanitized.count {
        case 6:
            return Color(
                .sRGB,
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0,
                opacity: 1.0
            )

        case 8:
            return Color(
                .sRGB,
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )

        default:
            return nil
        }
    }
}
