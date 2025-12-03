import SwiftUI

/// Renders UIComponent models as SwiftUI views
public struct ComponentRenderer: View {
    public let component: UIComponent

    public init(component: UIComponent) {
        self.component = component
    }

    public var body: some View {
        buildView(for: component)
    }

    @ViewBuilder
    private func buildView(for component: UIComponent) -> some View {
        switch component.type {
        case .layout(let props):
            buildLayout(children: component.children, properties: props)
        case .text(let props):
            buildText(properties: props)
        case .image(let props):
            buildImage(properties: props)
        case .button(let props):
            buildButton(children: component.children, properties: props)
        case .shape(let props):
            buildShape(properties: props)
        case .scrollView(let props):
            buildScrollView(children: component.children, properties: props)
        case .spacer:
            Spacer()
        case .divider:
            Divider()
        }
    }

    // MARK: - Layout Components

    @ViewBuilder
    private func buildLayout(children: [UIComponent]?, properties: LayoutProperties) -> some View {
        let spacing: CGFloat = properties.spacing ?? 8

        switch properties.layoutType {
        case .vstack:
            let alignment: HorizontalAlignment = parseHorizontalAlignment(properties.alignment)
            VStack(alignment: alignment, spacing: spacing) {
                if let children = children {
                    ForEach(children) { child in
                        ComponentRenderer(component: child)
                    }
                }
            }
            .applyCommonModifiers(properties.common)

        case .hstack:
            let alignment: VerticalAlignment = parseVerticalAlignment(properties.alignment)
            HStack(alignment: alignment, spacing: spacing) {
                if let children = children {
                    ForEach(children) { child in
                        ComponentRenderer(component: child)
                    }
                }
            }
            .applyCommonModifiers(properties.common)

        case .zstack:
            let alignment: Alignment = parseAlignment(properties.alignment)
            ZStack(alignment: alignment) {
                if let children = children {
                    ForEach(children) { child in
                        ComponentRenderer(component: child)
                    }
                }
            }
            .applyCommonModifiers(properties.common)
        }
    }

    @ViewBuilder
    private func buildScrollView(children: [UIComponent]?, properties: ScrollViewProperties) -> some View {
        let axis: Axis = parseAxis(properties.axis)
        let showsIndicators: Bool = properties.showsIndicators ?? true
        let shouldDisableClip: Bool = properties.common.clipped == false

        if axis == .vertical {
            ScrollView(.vertical, showsIndicators: showsIndicators) {
                if let children = children {
                    ForEach(children) { child in
                        ComponentRenderer(component: child)
                    }
                }
            }
            .scrollClipDisabled(shouldDisableClip)
            .applyCommonModifiersExceptClipped(properties.common)
        } else {
            ScrollView(.horizontal, showsIndicators: showsIndicators) {
                if let children = children {
                    ForEach(children) { child in
                        ComponentRenderer(component: child)
                    }
                }
            }
            .scrollClipDisabled(shouldDisableClip)
            .applyCommonModifiersExceptClipped(properties.common)
        }
    }

    // MARK: - Content Components

    @ViewBuilder
    private func buildText(properties: TextProperties) -> some View {
        let fontSize: CGFloat = properties.fontSize ?? 16
        let fontWeight: Font.Weight = parseFontWeight(properties.fontWeight)

        // Use custom font if specified in common properties, otherwise use system font
        if let fontName = properties.common.font {
            Text(properties.content)
                .font(.custom(fontName, size: fontSize))
                .fontWeight(fontWeight)
                .applyCommonModifiersExceptFont(properties.common)
        } else {
            Text(properties.content)
                .font(.system(size: fontSize, weight: fontWeight))
                .applyCommonModifiersExceptFont(properties.common)
        }
    }

    @ViewBuilder
    private func buildImage(properties: ImageProperties) -> some View {
        if let imageURL = properties.imageURL {
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    if properties.resizable ?? false {
                        image
                            .resizable()
                    } else {
                        image
                    }
                case .failure:
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            .applyCommonModifiers(properties.common)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func buildButton(children: [UIComponent]?, properties: ButtonProperties) -> some View {
        Button(action: {
            print("Button tapped: \(properties.action ?? "no action")")
        }) {
            if let children = children {
                ForEach(children) { child in
                    ComponentRenderer(component: child)
                }
            } else {
                Text(properties.label)
            }
        }
        .applyCommonModifiers(properties.common)
    }

    @ViewBuilder
    private func buildShape(properties: ShapeProperties) -> some View {
        switch properties.shapeType {
        case .rectangle:
            Rectangle()
                .applyCommonModifiers(properties.common)
        case .circle:
            Circle()
                .applyCommonModifiers(properties.common)
        }
    }

    // MARK: - Parsing Helpers

    private func parseHorizontalAlignment(_ alignment: String?) -> HorizontalAlignment {
        switch alignment?.lowercased() {
        case "leading": return .leading
        case "center": return .center
        case "trailing": return .trailing
        default: return .center
        }
    }

    private func parseVerticalAlignment(_ alignment: String?) -> VerticalAlignment {
        switch alignment?.lowercased() {
        case "top": return .top
        case "center": return .center
        case "bottom": return .bottom
        default: return .center
        }
    }

    private func parseAlignment(_ alignment: String?) -> Alignment {
        switch alignment?.lowercased() {
        case "topleft", "topleading": return .topLeading
        case "top": return .top
        case "topright", "toptrailing": return .topTrailing
        case "left", "leading": return .leading
        case "center": return .center
        case "right", "trailing": return .trailing
        case "bottomleft", "bottomleading": return .bottomLeading
        case "bottom": return .bottom
        case "bottomright", "bottomtrailing": return .bottomTrailing
        default: return .center
        }
    }

    private func parseFontWeight(_ weight: String?) -> Font.Weight {
        switch weight?.lowercased() {
        case "thin": return .thin
        case "light": return .light
        case "regular": return .regular
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .regular
        }
    }

    private func parseAxis(_ axis: String?) -> Axis {
        switch axis?.lowercased() {
        case "horizontal": return .horizontal
        default: return .vertical
        }
    }
}

// MARK: - View Modifiers

extension View {
    @ViewBuilder
    func applyCommonModifiers(_ properties: CommonProperties) -> some View {
        self
            .applyFont(properties)
            .applyFrame(properties)
            .applyAspectRatio(properties)
            .applyPadding(properties)
            .applyForegroundColor(properties)
            .applyBackgroundColor(properties)
            .applyCornerRadius(properties)
            .applyClipped(properties)
    }

    @ViewBuilder
    func applyCommonModifiersExceptClipped(_ properties: CommonProperties) -> some View {
        self
            .applyFont(properties)
            .applyFrame(properties)
            .applyAspectRatio(properties)
            .applyPadding(properties)
            .applyForegroundColor(properties)
            .applyBackgroundColor(properties)
            .applyCornerRadius(properties)
    }

    @ViewBuilder
    func applyCommonModifiersExceptFont(_ properties: CommonProperties) -> some View {
        self
            .applyFrame(properties)
            .applyAspectRatio(properties)
            .applyPadding(properties)
            .applyForegroundColor(properties)
            .applyBackgroundColor(properties)
            .applyCornerRadius(properties)
            .applyClipped(properties)
    }

    @ViewBuilder
    func applyFrame(_ properties: CommonProperties) -> some View {
        if let width = properties.width, let height = properties.height {
            self.frame(width: width, height: height)
        } else if let width = properties.width {
            self.frame(width: width)
        } else if let height = properties.height {
            self.frame(height: height)
        } else if let maxWidth = properties.maxWidth, let maxHeight = properties.maxHeight {
            self.frame(maxWidth: maxWidth, maxHeight: maxHeight)
        } else if let maxWidth = properties.maxWidth {
            self.frame(maxWidth: maxWidth)
        } else if let maxHeight = properties.maxHeight {
            self.frame(maxHeight: maxHeight)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyPadding(_ properties: CommonProperties) -> some View {
        if let padding = properties.padding {
            self.padding(padding)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyForegroundColor(_ properties: CommonProperties) -> some View {
        if let colorString = properties.foregroundColor {
            self.foregroundColor(parseColor(colorString))
        } else {
            self
        }
    }

    @ViewBuilder
    func applyBackgroundColor(_ properties: CommonProperties) -> some View {
        if let colorString = properties.backgroundColor {
            self.background(parseColor(colorString))
        } else {
            self
        }
    }

    @ViewBuilder
    func applyCornerRadius(_ properties: CommonProperties) -> some View {
        if let radius = properties.cornerRadius {
            self.cornerRadius(radius)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyClipped(_ properties: CommonProperties) -> some View {
        if let clipped = properties.clipped, clipped {
            self.clipped()
        } else {
            self
        }
    }

    @ViewBuilder
    func applyAspectRatio(_ properties: CommonProperties) -> some View {
        if let aspectRatio = properties.aspectRatio {
            let mode: ContentMode = parseContentMode(properties.contentMode)
            self.aspectRatio(aspectRatio, contentMode: mode)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyFont(_ properties: CommonProperties) -> some View {
        if let fontName = properties.font {
            self.font(.custom(fontName, size: 16))
        } else {
            self
        }
    }

    private func parseContentMode(_ contentMode: String?) -> ContentMode {
        switch contentMode?.lowercased() {
        case "fill": return .fill
        default: return .fit
        }
    }

    private func parseColor(_ colorString: String) -> Color {
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
        default:
            // Try to parse hex color
            if colorString.hasPrefix("#") {
                return Color(hex: colorString) ?? .primary
            }
            return .primary
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init?(hex: String) {
        var hexSanitized: String = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let length: Int = hexSanitized.count
        let r: Double
        let g: Double
        let b: Double
        let a: Double

        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
