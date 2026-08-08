import Foundation
import SwiftUI

/// Type-safe properties for each component type.
///
/// Encoding only. Components are decoded through ``UIComponent``, which reads the `type`
/// string first and then decodes the matching property struct from the flat `properties`
/// object — the synthesised enum decoding would expect a quite different shape.
enum ComponentProperties: Encodable, Equatable, Sendable {
    case layout(LayoutProperties)
    case text(TextProperties)
    case image(ImageProperties)
    case button(ButtonProperties)
    case shape(ShapeProperties)
    case scrollView(ScrollViewProperties)
    case spacer
    case divider

    /// A component type this version of the renderer does not know.
    ///
    /// Reaching the renderer at all means the caller asked for
    /// ``JUNParseOptions/UnknownComponentPolicy/placeholder``; under the default `.skip`
    /// policy these are dropped during decoding.
    case unknown(String)

    /// Returns the type string for JSON encoding.
    var typeString: String {
        switch self {
        case .layout(let props):
            switch props.layoutType {
            case .vstack: return "vstack"
            case .hstack: return "hstack"
            case .zstack: return "zstack"
            }
        case .text: return "text"
        case .image: return "image"
        case .button: return "button"
        case .shape(let props):
            switch props.shapeType {
            case .rectangle: return "rectangle"
            case .circle: return "circle"
            }
        case .scrollView: return "scrollView"
        case .spacer: return "spacer"
        case .divider: return "divider"
        case .unknown(let typeString): return typeString
        }
    }

    /// Whether this component renders children at all.
    var acceptsChildren: Bool {
        switch self {
        case .layout, .scrollView, .unknown: return true
        case .button: return true  // Non-standard; see `childrenAreNonStandard`.
        case .text, .image, .shape, .spacer, .divider: return false
        }
    }

    /// Whether accepting children here is an extension rather than specified behaviour.
    ///
    /// JUN v1.2 forbids children on `button`, but JUNSwiftUI has always rendered them as the
    /// button's label. Whether to change the specification or drop the capability is an open
    /// question, so the behaviour is preserved and the divergence is reported instead of being
    /// silently either way.
    var childrenAreNonStandard: Bool {
        if case .button = self { return true }
        return false
    }

    /// Encodes the associated property struct flatly, producing the `properties` object the
    /// specification describes rather than Swift's synthesised enum representation.
    func encode(to encoder: Encoder) throws {
        switch self {
        case .layout(let props): try props.encode(to: encoder)
        case .text(let props): try props.encode(to: encoder)
        case .image(let props): try props.encode(to: encoder)
        case .button(let props): try props.encode(to: encoder)
        case .shape(let props): try props.encode(to: encoder)
        case .scrollView(let props): try props.encode(to: encoder)
        case .spacer, .divider, .unknown: try CommonProperties().encode(to: encoder)
        }
    }
}

// MARK: - Layout Properties (VStack, HStack, ZStack)

struct LayoutProperties: Codable, Equatable, Sendable {
    let layoutType: LayoutType
    let spacing: CGFloat?
    let alignment: String?
    let common: CommonProperties

    init(
        layoutType: LayoutType = .vstack,
        spacing: CGFloat? = nil,
        alignment: String? = nil,
        common: CommonProperties = CommonProperties()
    ) {
        self.layoutType = layoutType
        self.spacing = spacing
        self.alignment = alignment
        self.common = common
    }

    init(from decoder: Decoder, layoutType: LayoutType) throws {
        let context: JUNDecodingContext = decoder.junContext
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)

        self.layoutType = layoutType
        self.spacing = try container.junDecode(CGFloat.self, forKey: .spacing, context)
        self.alignment = try container.junDecode(String.self, forKey: .alignment, context)
        self.common = try CommonProperties(from: decoder)
    }

    init(from decoder: Decoder) throws {
        try self.init(from: decoder, layoutType: .vstack)
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(spacing, forKey: .spacing)
        try container.encodeIfPresent(alignment, forKey: .alignment)
        try common.encode(to: encoder)
    }

    private enum CodingKeys: String, CodingKey {
        case spacing, alignment
    }
}

enum LayoutType: Equatable, Sendable {
    case vstack
    case hstack
    case zstack
}

// MARK: - Text Properties

struct TextProperties: Codable, Equatable, Sendable {
    let content: String
    let fontSize: CGFloat?
    let fontWeight: String?
    let common: CommonProperties

    init(
        content: String,
        fontSize: CGFloat? = nil,
        fontWeight: String? = nil,
        common: CommonProperties = CommonProperties()
    ) {
        self.content = content
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.common = common
    }

    init(from decoder: Decoder) throws {
        let context: JUNDecodingContext = decoder.junContext
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)

        self.content = try container.junDecodeRequired(String.self, forKey: .content, context) ?? ""
        self.fontSize = try container.junDecode(CGFloat.self, forKey: .fontSize, context)
        self.fontWeight = try container.junDecode(String.self, forKey: .fontWeight, context)
        self.common = try CommonProperties(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(fontSize, forKey: .fontSize)
        try container.encodeIfPresent(fontWeight, forKey: .fontWeight)
        try common.encode(to: encoder)
    }

    private enum CodingKeys: String, CodingKey {
        case content, fontSize, fontWeight
    }
}

// MARK: - Image Properties

/// Where an image comes from.
///
/// The three sources differ in who owns the asset, which is why they are distinct properties
/// rather than one overloaded string: `url` ships with the document, `name` belongs to the
/// host application, and `system` belongs to the platform.
enum ImageSource: Equatable, Sendable {
    case url(String)
    case name(String)
    case system(String)
}

struct ImageProperties: Codable, Equatable, Sendable {
    let source: ImageSource?
    let resizable: Bool?
    let common: CommonProperties

    init(
        source: ImageSource? = nil,
        resizable: Bool? = nil,
        common: CommonProperties = CommonProperties()
    ) {
        self.source = source
        self.resizable = resizable
        self.common = common
    }

    init(from decoder: Decoder) throws {
        let context: JUNDecodingContext = decoder.junContext
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)

        let imageURL: String? = try container.junDecode(String.self, forKey: .imageURL, context)
        let imageName: String? = try container.junDecode(String.self, forKey: .imageName, context)
        let systemImage: String? = try container.junDecode(String.self, forKey: .systemImage, context)

        let provided: [ImageSource] = [
            imageURL.map(ImageSource.url),
            imageName.map(ImageSource.name),
            systemImage.map(ImageSource.system)
        ].compactMap { $0 }

        switch provided.count {
        case 1:
            self.source = provided[0]

        case 0:
            context.fail(
                "image requires one of 'imageURL', 'imageName' or 'systemImage'",
                at: decoder.codingPath
            )
            if context.options.invalidValues == .fail {
                throw JUNParseError.invalidValue(
                    path: JUNPath.describe(decoder.codingPath),
                    message: "image has no source"
                )
            }
            self.source = nil

        default:
            // Ambiguous rather than absent: render something, but say so.
            context.fail(
                "image specifies more than one source; using the first of imageURL, imageName, systemImage",
                at: decoder.codingPath
            )
            if context.options.invalidValues == .fail {
                throw JUNParseError.invalidValue(
                    path: JUNPath.describe(decoder.codingPath),
                    message: "image has \(provided.count) sources, expected exactly one"
                )
            }
            self.source = provided[0]
        }

        self.resizable = try container.junDecode(Bool.self, forKey: .resizable, context)
        self.common = try CommonProperties(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)

        switch source {
        case .url(let value): try container.encode(value, forKey: .imageURL)
        case .name(let value): try container.encode(value, forKey: .imageName)
        case .system(let value): try container.encode(value, forKey: .systemImage)
        case nil: break
        }

        try container.encodeIfPresent(resizable, forKey: .resizable)
        try common.encode(to: encoder)
    }

    private enum CodingKeys: String, CodingKey {
        case imageURL, imageName, systemImage, resizable
    }
}

// MARK: - Button Properties

struct ButtonProperties: Codable, Equatable, Sendable {
    let label: String
    let action: JUNAction?
    let common: CommonProperties

    init(
        label: String,
        action: JUNAction? = nil,
        common: CommonProperties = CommonProperties()
    ) {
        self.label = label
        self.action = action
        self.common = common
    }

    init(from decoder: Decoder) throws {
        let context: JUNDecodingContext = decoder.junContext
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)

        self.label = try container.junDecodeRequired(String.self, forKey: .label, context) ?? "Button"
        self.action = try container.junDecode(JUNAction.self, forKey: .action, context)
        self.common = try CommonProperties(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encodeIfPresent(action, forKey: .action)
        try common.encode(to: encoder)
    }

    private enum CodingKeys: String, CodingKey {
        case label, action
    }
}

// MARK: - Shape Properties

struct ShapeProperties: Codable, Equatable, Sendable {
    let shapeType: ShapeType
    let common: CommonProperties

    init(
        shapeType: ShapeType = .rectangle,
        common: CommonProperties = CommonProperties()
    ) {
        self.shapeType = shapeType
        self.common = common
    }

    init(from decoder: Decoder, shapeType: ShapeType) throws {
        self.shapeType = shapeType
        self.common = try CommonProperties(from: decoder)
    }

    init(from decoder: Decoder) throws {
        try self.init(from: decoder, shapeType: .rectangle)
    }

    func encode(to encoder: Encoder) throws {
        try common.encode(to: encoder)
    }
}

enum ShapeType: Equatable, Sendable {
    case rectangle
    case circle
}

// MARK: - ScrollView Properties

struct ScrollViewProperties: Codable, Equatable, Sendable {
    let axis: String?
    let showsIndicators: Bool?
    let common: CommonProperties

    init(
        axis: String? = nil,
        showsIndicators: Bool? = nil,
        common: CommonProperties = CommonProperties()
    ) {
        self.axis = axis
        self.showsIndicators = showsIndicators
        self.common = common
    }

    init(from decoder: Decoder) throws {
        let context: JUNDecodingContext = decoder.junContext
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)

        self.axis = try container.junDecode(String.self, forKey: .axis, context)
        self.showsIndicators = try container.junDecode(Bool.self, forKey: .showsIndicators, context)
        self.common = try CommonProperties(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(axis, forKey: .axis)
        try container.encodeIfPresent(showsIndicators, forKey: .showsIndicators)
        try common.encode(to: encoder)
    }

    private enum CodingKeys: String, CodingKey {
        case axis, showsIndicators
    }
}

// MARK: - Common Properties (applicable to all components)

struct CommonProperties: Codable, Equatable, Sendable {
    let padding: CGFloat?
    let width: CGFloat?
    let height: CGFloat?
    let maxWidth: CGFloat?
    let maxHeight: CGFloat?
    let foregroundColor: String?
    let backgroundColor: String?
    let cornerRadius: CGFloat?
    let clipped: Bool?
    let aspectRatio: CGFloat?
    let contentMode: String?
    let font: String?

    init(
        padding: CGFloat? = nil,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        foregroundColor: String? = nil,
        backgroundColor: String? = nil,
        cornerRadius: CGFloat? = nil,
        clipped: Bool? = nil,
        aspectRatio: CGFloat? = nil,
        contentMode: String? = nil,
        font: String? = nil
    ) {
        self.padding = padding
        self.width = width
        self.height = height
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.clipped = clipped
        self.aspectRatio = aspectRatio
        self.contentMode = contentMode
        self.font = font
    }

    init(from decoder: Decoder) throws {
        let context: JUNDecodingContext = decoder.junContext
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)

        self.padding = try container.junDecode(CGFloat.self, forKey: .padding, context)
        self.width = try container.junDecode(CGFloat.self, forKey: .width, context)
        self.height = try container.junDecode(CGFloat.self, forKey: .height, context)
        self.maxWidth = try container.junDecode(CGFloat.self, forKey: .maxWidth, context)
        self.maxHeight = try container.junDecode(CGFloat.self, forKey: .maxHeight, context)
        self.foregroundColor = try container.junDecode(String.self, forKey: .foregroundColor, context)
        self.backgroundColor = try container.junDecode(String.self, forKey: .backgroundColor, context)
        self.cornerRadius = try container.junDecode(CGFloat.self, forKey: .cornerRadius, context)
        self.clipped = try container.junDecode(Bool.self, forKey: .clipped, context)
        self.aspectRatio = try container.junDecode(CGFloat.self, forKey: .aspectRatio, context)
        self.contentMode = try container.junDecode(String.self, forKey: .contentMode, context)
        self.font = try container.junDecode(String.self, forKey: .font, context)
    }

    private enum CodingKeys: String, CodingKey {
        case padding, width, height, maxWidth, maxHeight
        case foregroundColor, backgroundColor, cornerRadius, clipped
        case aspectRatio, contentMode, font
    }
}

// MARK: - Convenience Accessors

extension ComponentProperties {
    var common: CommonProperties {
        switch self {
        case .layout(let props): return props.common
        case .text(let props): return props.common
        case .image(let props): return props.common
        case .button(let props): return props.common
        case .shape(let props): return props.common
        case .scrollView(let props): return props.common
        case .spacer, .divider, .unknown: return CommonProperties()
        }
    }
}
