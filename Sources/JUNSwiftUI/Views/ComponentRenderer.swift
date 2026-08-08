import SwiftUI

/// Renders a JUN component tree as SwiftUI views.
public struct ComponentRenderer: View {
    public let component: UIComponent

    @Environment(\.junActionHandler) private var actionHandler: JUNActionHandler

    public init(component: UIComponent) {
        self.component = component
    }

    /// Renders the root of a parsed document.
    public init(document: JUNDocument) {
        self.component = document.root
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
        case .unknown(let typeString):
            buildUnknown(typeString: typeString)
        }
    }

    // MARK: - Layout Components

    @ViewBuilder
    private func buildLayout(children: [UIComponent]?, properties: LayoutProperties) -> some View {
        let spacing: CGFloat = properties.spacing ?? 8

        switch properties.layoutType {
        case .vstack:
            VStack(alignment: JUNParse.horizontalAlignment(properties.alignment), spacing: spacing) {
                renderChildren(children)
            }
            .applyCommonModifiers(properties.common)

        case .hstack:
            HStack(alignment: JUNParse.verticalAlignment(properties.alignment), spacing: spacing) {
                renderChildren(children)
            }
            .applyCommonModifiers(properties.common)

        case .zstack:
            ZStack(alignment: JUNParse.alignment(properties.alignment)) {
                renderChildren(children)
            }
            .applyCommonModifiers(properties.common)
        }
    }

    @ViewBuilder
    private func buildScrollView(children: [UIComponent]?, properties: ScrollViewProperties) -> some View {
        let axis: Axis = JUNParse.axis(properties.axis)
        let showsIndicators: Bool = properties.showsIndicators ?? true
        let disableClip: Bool = properties.common.clipped == false

        if axis == .vertical {
            ScrollView(.vertical, showsIndicators: showsIndicators) {
                renderChildren(children)
            }
            .scrollClipDisabled(disableClip)
            .applyCommonModifiers(properties.common, skipping: .clipped)
        } else {
            ScrollView(.horizontal, showsIndicators: showsIndicators) {
                renderChildren(children)
            }
            .scrollClipDisabled(disableClip)
            .applyCommonModifiers(properties.common, skipping: .clipped)
        }
    }

    @ViewBuilder
    private func renderChildren(_ children: [UIComponent]?) -> some View {
        if let children {
            ForEach(children) { child in
                ComponentRenderer(component: child)
            }
        }
    }

    // MARK: - Content Components

    @ViewBuilder
    private func buildText(properties: TextProperties) -> some View {
        let fontSize: CGFloat = properties.fontSize ?? 16
        let fontWeight: Font.Weight = JUNParse.fontWeight(properties.fontWeight)

        if let fontName = properties.common.font {
            Text(properties.content)
                .font(.custom(fontName, size: fontSize))
                .fontWeight(fontWeight)
                .applyCommonModifiers(properties.common, skipping: .font)
        } else {
            Text(properties.content)
                .font(.system(size: fontSize, weight: fontWeight))
                .applyCommonModifiers(properties.common, skipping: .font)
        }
    }

    @ViewBuilder
    private func buildImage(properties: ImageProperties) -> some View {
        let resizable: Bool = properties.resizable ?? false

        switch properties.source {
        case .url(let urlString):
            AsyncImage(url: URL(string: urlString)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    resize(image, resizable)
                case .failure:
                    Self.unavailableImage
                @unknown default:
                    Self.unavailableImage
                }
            }
            .applyCommonModifiers(properties.common)

        case .name(let name):
            resize(Image(name), resizable)
                .applyCommonModifiers(properties.common)

        case .system(let name):
            resize(Image(systemName: name), resizable)
                .applyCommonModifiers(properties.common)

        case nil:
            // The source was missing or ambiguous; the diagnostic was recorded during parsing.
            // Showing the placeholder rather than nothing keeps the layout honest about the
            // fact that something was meant to be here.
            Self.unavailableImage
                .applyCommonModifiers(properties.common)
        }
    }

    @ViewBuilder
    private func resize(_ image: Image, _ resizable: Bool) -> some View {
        if resizable {
            image.resizable()
        } else {
            image
        }
    }

    private static var unavailableImage: some View {
        Image(systemName: "photo")
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func buildButton(children: [UIComponent]?, properties: ButtonProperties) -> some View {
        Button {
            if let action = properties.action {
                actionHandler(action)
            }
        } label: {
            // Children as the label are a JUNSwiftUI extension the parser warns about; `label`
            // remains the specified form and the fallback.
            if let children, !children.isEmpty {
                renderChildren(children)
            } else {
                Text(properties.label)
            }
        }
        .applyCommonModifiers(properties.common)
    }

    @ViewBuilder
    private func buildShape(properties: ShapeProperties) -> some View {
        let common: CommonProperties = properties.common

        // A shape fills itself with its foreground style, so routing `backgroundColor` to
        // `.background` would paint it behind an opaque fill and produce a black shape. The
        // specification makes `foregroundColor` the fill and requires falling back to
        // `backgroundColor`, which is how nearly every document in the wild writes it.
        let fillString: String? = common.foregroundColor ?? common.backgroundColor
        let fill: Color = fillString.flatMap(JUNColor.parse) ?? .primary
        let backgroundWasUsedAsFill: Bool = common.foregroundColor == nil && common.backgroundColor != nil

        let skipping: CommonModifiers.Skip = backgroundWasUsedAsFill
            ? [.foregroundColor, .backgroundColor]
            : .foregroundColor

        switch properties.shapeType {
        case .rectangle:
            Rectangle()
                .fill(fill)
                .applyCommonModifiers(common, skipping: skipping)

        case .circle:
            Circle()
                .fill(fill)
                .applyCommonModifiers(common, skipping: skipping)
        }
    }

    @ViewBuilder
    private func buildUnknown(typeString: String) -> some View {
        // Only reachable under `.placeholder`; the default policy drops these while parsing.
        Text("Unsupported component: \(typeString)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(8)
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(.secondary, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
    }
}

// MARK: - Value Parsing

/// Maps JUN's string enumerations onto SwiftUI values.
///
/// Every one of these falls back to the documented default rather than failing: unrecognised
/// enum values are a forward-compatibility case, and the parser has already recorded a
/// diagnostic for anything malformed.
enum JUNParse {

    static func horizontalAlignment(_ alignment: String?) -> HorizontalAlignment {
        switch alignment?.lowercased() {
        case "leading": return .leading
        case "trailing": return .trailing
        default: return .center
        }
    }

    static func verticalAlignment(_ alignment: String?) -> VerticalAlignment {
        switch alignment?.lowercased() {
        case "top": return .top
        case "bottom": return .bottom
        default: return .center
        }
    }

    static func alignment(_ alignment: String?) -> Alignment {
        switch alignment?.lowercased() {
        case "topleft", "topleading": return .topLeading
        case "top": return .top
        case "topright", "toptrailing": return .topTrailing
        case "left", "leading": return .leading
        case "right", "trailing": return .trailing
        case "bottomleft", "bottomleading": return .bottomLeading
        case "bottom": return .bottom
        case "bottomright", "bottomtrailing": return .bottomTrailing
        default: return .center
        }
    }

    static func fontWeight(_ weight: String?) -> Font.Weight {
        switch weight?.lowercased() {
        case "thin": return .thin
        case "light": return .light
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .regular
        }
    }

    static func axis(_ axis: String?) -> Axis {
        switch axis?.lowercased() {
        case "horizontal": return .horizontal
        default: return .vertical
        }
    }

    static func contentMode(_ contentMode: String?) -> ContentMode {
        switch contentMode?.lowercased() {
        case "fill": return .fill
        default: return .fit
        }
    }
}
