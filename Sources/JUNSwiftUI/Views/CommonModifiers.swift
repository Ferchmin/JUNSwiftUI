import SwiftUI

/// Applies the JUN universal properties.
///
/// One modifier rather than a set of `View` extensions, so the helpers do not appear on every
/// view in the module — and so the order in which the properties are applied is stated in one
/// place, since that order is load-bearing.
struct CommonModifiers: ViewModifier {

    /// Properties a component renders itself and therefore does not want applied again.
    struct Skip: OptionSet {
        let rawValue: Int

        /// Text applies `font` together with `fontSize`, which is not a universal property.
        static let font: Skip = Skip(rawValue: 1 << 0)

        /// ScrollView clips through `scrollClipDisabled` instead.
        static let clipped: Skip = Skip(rawValue: 1 << 1)

        /// Shapes take their fill from `foregroundColor`.
        static let foregroundColor: Skip = Skip(rawValue: 1 << 2)

        /// Shapes fall back to `backgroundColor` for their fill, and must not then paint it
        /// behind themselves as well.
        static let backgroundColor: Skip = Skip(rawValue: 1 << 3)
    }

    let properties: CommonProperties
    var skipping: Skip = []

    func body(content: Content) -> some View {
        content
            .junFont(properties, skipping: skipping)
            .junAspectRatio(properties)
            // Padding precedes the frame so that `width` and `height` describe the component's
            // total size, with padding inside it — which is what "internal padding" means in
            // the specification.
            .junPadding(properties)
            .junFrame(properties)
            .junForegroundColor(properties, skipping: skipping)
            .junBackgroundColor(properties, skipping: skipping)
            .junCornerRadius(properties)
            .junClipped(properties, skipping: skipping)
    }
}

extension View {
    func applyCommonModifiers(
        _ properties: CommonProperties,
        skipping: CommonModifiers.Skip = []
    ) -> some View {
        modifier(CommonModifiers(properties: properties, skipping: skipping))
    }
}

// MARK: - Individual Properties

private extension View {

    @ViewBuilder
    func junFrame(_ properties: CommonProperties) -> some View {
        let hasFixed: Bool = properties.width != nil || properties.height != nil
        let hasBounds: Bool = properties.maxWidth != nil || properties.maxHeight != nil

        // Fixed and maximum sizing compose; neither silently drops the other.
        if hasFixed && hasBounds {
            self
                .frame(width: properties.width, height: properties.height)
                .frame(maxWidth: properties.maxWidth, maxHeight: properties.maxHeight)
        } else if hasFixed {
            self.frame(width: properties.width, height: properties.height)
        } else if hasBounds {
            self.frame(maxWidth: properties.maxWidth, maxHeight: properties.maxHeight)
        } else {
            self
        }
    }

    @ViewBuilder
    func junPadding(_ properties: CommonProperties) -> some View {
        if let padding = properties.padding {
            self.padding(padding)
        } else {
            self
        }
    }

    @ViewBuilder
    func junForegroundColor(_ properties: CommonProperties, skipping: CommonModifiers.Skip) -> some View {
        if !skipping.contains(.foregroundColor),
           let colorString = properties.foregroundColor,
           let color = JUNColor.parse(colorString) {
            self.foregroundStyle(color)
        } else {
            self
        }
    }

    @ViewBuilder
    func junBackgroundColor(_ properties: CommonProperties, skipping: CommonModifiers.Skip) -> some View {
        if !skipping.contains(.backgroundColor),
           let colorString = properties.backgroundColor,
           let color = JUNColor.parse(colorString) {
            self.background(color)
        } else {
            self
        }
    }

    @ViewBuilder
    func junCornerRadius(_ properties: CommonProperties) -> some View {
        if let radius = properties.cornerRadius {
            self.clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            self
        }
    }

    @ViewBuilder
    func junClipped(_ properties: CommonProperties, skipping: CommonModifiers.Skip) -> some View {
        if !skipping.contains(.clipped), properties.clipped == true {
            self.clipped()
        } else {
            self
        }
    }

    @ViewBuilder
    func junAspectRatio(_ properties: CommonProperties) -> some View {
        if let aspectRatio = properties.aspectRatio {
            self.aspectRatio(aspectRatio, contentMode: JUNParse.contentMode(properties.contentMode))
        } else {
            self
        }
    }

    @ViewBuilder
    func junFont(_ properties: CommonProperties, skipping: CommonModifiers.Skip) -> some View {
        if !skipping.contains(.font), let fontName = properties.font {
            // `fontSize` is text-only in the format, so a container carrying `font` has no size
            // to go with it. Anchoring to `.body` at its standard size means descendants
            // inherit the family and still scale with Dynamic Type; any text with its own
            // `fontSize` overrides this outright.
            self.font(.custom(fontName, size: 17, relativeTo: .body))
        } else {
            self
        }
    }
}
