import Foundation
import SwiftUI

/// Represents a UI component that can be decoded from JSON and rendered as SwiftUI
public struct UIComponent {
    public let id: UUID
    let type: ComponentProperties
    let children: [UIComponent]?

    init(
        id: UUID = UUID(),
        type: ComponentProperties,
        children: [UIComponent]? = nil
    ) {
        self.id = id
        self.type = type
        self.children = children
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, type, properties, children
    }

    // Custom decoding to:
    // 1. Generate UUID if not present
    // 2. Read type field and decode corresponding properties
    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)

        // Decode ID (generate if not present)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()

        // Decode type to determine which properties to decode
        let typeString: String = try container.decode(String.self, forKey: .type)

        // Decode properties based on type string
        if container.contains(.properties) {
            let propertiesDecoder: Decoder = try container.superDecoder(forKey: .properties)
            self.type = try Self.decodeType(for: typeString, from: propertiesDecoder)
        } else {
            // No properties provided, use defaults
            self.type = Self.defaultType(for: typeString)
        }

        // Decode children
        self.children = try? container.decode([UIComponent].self, forKey: .children)
    }

    public func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)

        // Encode type string based on ComponentProperties case
        try container.encode(type.typeString, forKey: .type)

        try container.encode(type, forKey: .properties)
        try container.encodeIfPresent(children, forKey: .children)
    }

    // MARK: - Helper Methods

    private static func decodeType(for typeString: String, from decoder: Decoder) throws -> ComponentProperties {
        switch typeString.lowercased() {
        case "vstack":
            let props: LayoutProperties = try LayoutProperties(from: decoder, layoutType: .vstack)
            return .layout(props)

        case "hstack":
            let props: LayoutProperties = try LayoutProperties(from: decoder, layoutType: .hstack)
            return .layout(props)

        case "zstack":
            let props: LayoutProperties = try LayoutProperties(from: decoder, layoutType: .zstack)
            return .layout(props)

        case "text":
            let props: TextProperties = try TextProperties(from: decoder)
            return .text(props)

        case "image":
            let props: ImageProperties = try ImageProperties(from: decoder)
            return .image(props)

        case "button":
            let props: ButtonProperties = try ButtonProperties(from: decoder)
            return .button(props)

        case "rectangle":
            let props: ShapeProperties = try ShapeProperties(from: decoder, shapeType: .rectangle)
            return .shape(props)

        case "circle":
            let props: ShapeProperties = try ShapeProperties(from: decoder, shapeType: .circle)
            return .shape(props)

        case "scrollview":
            let props: ScrollViewProperties = try ScrollViewProperties(from: decoder)
            return .scrollView(props)

        case "spacer":
            return .spacer

        case "divider":
            return .divider

        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: try decoder.container(keyedBy: CodingKeys.self),
                debugDescription: "Unknown component type: \(typeString)"
            )
        }
    }

    private static func defaultType(for typeString: String) -> ComponentProperties {
        switch typeString.lowercased() {
        case "vstack", "hstack", "zstack":
            return .layout(LayoutProperties())
        case "text":
            return .text(TextProperties(content: ""))
        case "image":
            return .image(ImageProperties())
        case "button":
            return .button(ButtonProperties(label: "Button"))
        case "rectangle", "circle":
            return .shape(ShapeProperties())
        case "scrollview":
            return .scrollView(ScrollViewProperties())
        case "spacer":
            return .spacer
        case "divider":
            return .divider
        default:
            return .text(TextProperties(content: "Unknown type: \(typeString)"))
        }
    }
}

extension UIComponent: Equatable { }
extension UIComponent: Codable { }
extension UIComponent: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
extension UIComponent: Identifiable { }
