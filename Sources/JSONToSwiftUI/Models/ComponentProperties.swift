import Foundation
import SwiftUI

/// Type-safe properties for each component type
enum ComponentProperties: Codable {
    case layout(LayoutProperties)
    case text(TextProperties)
    case image(ImageProperties)
    case button(ButtonProperties)
    case shape(ShapeProperties)
    case scrollView(ScrollViewProperties)
    case spacer
    case divider

    /// Returns the type string for JSON encoding
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
        }
    }
}

// MARK: - Layout Properties (VStack, HStack, ZStack)

struct LayoutProperties: Codable {
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

    // Custom decoding to flatten common properties from JSON
    init(from decoder: Decoder, layoutType: LayoutType) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.layoutType = layoutType
        self.spacing = try? container.decode(CGFloat.self, forKey: .spacing)
        self.alignment = try? container.decode(String.self, forKey: .alignment)
        self.common = try CommonProperties(from: decoder)
    }

    init(from decoder: Decoder) throws {
        // Fallback if called without layoutType
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

enum LayoutType {
    case vstack
    case hstack
    case zstack
}

// MARK: - Text Properties

struct TextProperties: Codable {
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
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.content = (try? container.decode(String.self, forKey: .content)) ?? ""
        self.fontSize = try? container.decode(CGFloat.self, forKey: .fontSize)
        self.fontWeight = try? container.decode(String.self, forKey: .fontWeight)
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

struct ImageProperties: Codable {
    let imageURL: String?
    let resizable: Bool?
    let common: CommonProperties

    init(
        imageURL: String? = nil,
        resizable: Bool? = nil,
        common: CommonProperties = CommonProperties()
    ) {
        self.imageURL = imageURL
        self.resizable = resizable
        self.common = common
    }

    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.imageURL = try? container.decode(String.self, forKey: .imageURL)
        self.resizable = try? container.decode(Bool.self, forKey: .resizable)
        self.common = try CommonProperties(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(resizable, forKey: .resizable)
        try common.encode(to: encoder)
    }

    private enum CodingKeys: String, CodingKey {
        case imageURL, resizable
    }
}

// MARK: - Button Properties

struct ButtonProperties: Codable {
    let label: String
    let action: String?
    let common: CommonProperties

    init(
        label: String,
        action: String? = nil,
        common: CommonProperties = CommonProperties()
    ) {
        self.label = label
        self.action = action
        self.common = common
    }

    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        // Try "label" first, fall back to legacy "buttonLabel"
        self.label = (try? container.decode(String.self, forKey: .label))
            ?? (try? container.decode(String.self, forKey: .buttonLabel))
            ?? "Button"
        // Try "action" first, fall back to legacy "buttonAction"
        self.action = (try? container.decode(String.self, forKey: .action))
            ?? (try? container.decode(String.self, forKey: .buttonAction))
        self.common = try CommonProperties(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encodeIfPresent(action, forKey: .action)
        try common.encode(to: encoder)
    }

    private enum CodingKeys: String, CodingKey {
        case label, action, buttonLabel, buttonAction
    }
}

// MARK: - Shape Properties

struct ShapeProperties: Codable {
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
        // Fallback if called without shapeType
        try self.init(from: decoder, shapeType: .rectangle)
    }

    func encode(to encoder: Encoder) throws {
        try common.encode(to: encoder)
    }
}

enum ShapeType {
    case rectangle
    case circle
}

// MARK: - ScrollView Properties

struct ScrollViewProperties: Codable {
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
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        // Try "axis" first, fall back to legacy "scrollAxis"
        self.axis = (try? container.decode(String.self, forKey: .axis))
            ?? (try? container.decode(String.self, forKey: .scrollAxis))
        self.showsIndicators = try? container.decode(Bool.self, forKey: .showsIndicators)
        self.common = try CommonProperties(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(axis, forKey: .axis)
        try container.encodeIfPresent(showsIndicators, forKey: .showsIndicators)
        try common.encode(to: encoder)
    }

    private enum CodingKeys: String, CodingKey {
        case axis, showsIndicators, scrollAxis
    }
}

// MARK: - Common Properties (applicable to all components)

struct CommonProperties: Codable {
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
        contentMode: String? = nil
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
        case .spacer, .divider: return CommonProperties()
        }
    }
}
