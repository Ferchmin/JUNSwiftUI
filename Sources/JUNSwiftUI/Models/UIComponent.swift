import Foundation
import SwiftUI

/// A UI component decoded from a JUN document and rendered as SwiftUI.
public struct UIComponent: Sendable {
    public let id: UUID
    let type: ComponentProperties
    let children: [UIComponent]?

    /// The key name used for nesting, which is also how parse depth is measured.
    static let childrenKeyName: String = "children"

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

    public init(from decoder: Decoder) throws {
        let context: JUNDecodingContext = decoder.junContext

        // Enforced before anything else: a depth bomb must not be parsed on the way to being
        // rejected.
        try context.registerComponent(at: decoder.codingPath)

        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)

        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()

        guard let typeString = try container.junDecodeRequired(String.self, forKey: .type, context) else {
            throw JUNComponentUnrenderable()
        }

        // Decode the properties for this type. A component with no `properties` object is not
        // an error in itself; it is only an error if the type has required properties.
        if container.contains(.properties) {
            let propertiesDecoder: Decoder = try container.superDecoder(forKey: .properties)
            self.type = try Self.decodeType(for: typeString, from: propertiesDecoder, context: context)
        } else {
            self.type = try Self.defaultType(
                for: typeString,
                context: context,
                codingPath: decoder.codingPath
            )
        }

        let decodedChildren: [UIComponent]? = try Self.decodeChildren(from: container, context: context)

        let childrenPath: [CodingKey] = JUNPath.appending(CodingKeys.children, to: decoder.codingPath)

        if let decodedChildren, !decodedChildren.isEmpty, !self.type.acceptsChildren {
            context.warn(
                "'\(typeString)' does not accept children; \(decodedChildren.count) ignored",
                at: childrenPath
            )
            self.children = nil
        } else {
            if decodedChildren?.isEmpty == false, self.type.childrenAreNonStandard {
                context.warn(
                    "children on '\(typeString)' are a JUNSwiftUI extension and are not part of JUN v1.2",
                    at: childrenPath
                )
            }
            self.children = decodedChildren
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type.typeString, forKey: .type)
        try container.encode(type, forKey: .properties)
        try container.encodeIfPresent(children, forKey: .children)
    }

    // MARK: - Children

    /// Decodes children one element at a time, so a single malformed component cannot take out
    /// its siblings.
    private static func decodeChildren(
        from container: KeyedDecodingContainer<CodingKeys>,
        context: JUNDecodingContext
    ) throws -> [UIComponent]? {
        guard container.contains(.children) else { return nil }

        var childContainer: UnkeyedDecodingContainer

        do {
            childContainer = try container.nestedUnkeyedContainer(forKey: .children)
        } catch {
            let path: [CodingKey] = JUNPath.appending(CodingKeys.children, to: container.codingPath)
            context.fail("'children' must be an array", at: path)

            if context.options.invalidValues == .fail {
                throw JUNParseError.invalidValue(
                    path: JUNPath.describe(path),
                    message: "'children' must be an array"
                )
            }

            return nil
        }

        var children: [UIComponent] = []

        while !childContainer.isAtEnd {
            let indexBeforeDecode: Int = childContainer.currentIndex

            do {
                let child: UIComponent = try childContainer.decode(UIComponent.self)

                switch (child.type, context.options.unknownComponents) {
                case (.unknown, .skip):
                    break  // Diagnostic already recorded while decoding the child.

                case (.unknown(let name), .fail):
                    throw JUNParseError.unsupportedComponent(
                        type: name,
                        path: JUNPath.describe(childContainer.codingPath)
                    )

                default:
                    children.append(child)
                }
            } catch let error as JUNParseError {
                throw error
            } catch {
                if !(error is JUNComponentUnrenderable) {
                    context.fail("\(error)", at: childContainer.codingPath)
                }

                // A failed decode leaves the container's index where it was, so consume the
                // element with a type that cannot fail in order to reach the next sibling.
                _ = try? childContainer.decode(SkippedElement.self)
            }

            // Defensive: never spin on an element that refuses to be consumed.
            if childContainer.currentIndex == indexBeforeDecode {
                context.fail("could not advance past a malformed child", at: childContainer.codingPath)
                break
            }
        }

        return children
    }

    // MARK: - Type Dispatch

    private static func decodeType(
        for typeString: String,
        from decoder: Decoder,
        context: JUNDecodingContext
    ) throws -> ComponentProperties {
        switch typeString.lowercased() {
        case "vstack":
            return .layout(try LayoutProperties(from: decoder, layoutType: .vstack))

        case "hstack":
            return .layout(try LayoutProperties(from: decoder, layoutType: .hstack))

        case "zstack":
            return .layout(try LayoutProperties(from: decoder, layoutType: .zstack))

        case "text":
            return .text(try TextProperties(from: decoder))

        case "image":
            return .image(try ImageProperties(from: decoder))

        case "button":
            return .button(try ButtonProperties(from: decoder))

        case "rectangle":
            return .shape(try ShapeProperties(from: decoder, shapeType: .rectangle))

        case "circle":
            return .shape(try ShapeProperties(from: decoder, shapeType: .circle))

        case "scrollview":
            return .scrollView(try ScrollViewProperties(from: decoder))

        case "spacer":
            return .spacer

        case "divider":
            return .divider

        default:
            return try unknown(typeString, context: context, codingPath: decoder.codingPath)
        }
    }

    /// Builds a component for a type that carried no `properties` object at all.
    ///
    /// Handled identically to the case where properties are present, so that behaviour never
    /// depends on incidental document shape — the specification requires an unknown type to
    /// degrade the same way either way.
    private static func defaultType(
        for typeString: String,
        context: JUNDecodingContext,
        codingPath: [CodingKey]
    ) throws -> ComponentProperties {
        func missing(_ property: String) throws {
            let message: String = "missing required property '\(property)'"
            context.fail(message, at: codingPath)

            if context.options.invalidValues == .fail {
                throw JUNParseError.invalidValue(
                    path: JUNPath.describe(codingPath),
                    message: message
                )
            }
        }

        switch typeString.lowercased() {
        case "vstack": return .layout(LayoutProperties(layoutType: .vstack))
        case "hstack": return .layout(LayoutProperties(layoutType: .hstack))
        case "zstack": return .layout(LayoutProperties(layoutType: .zstack))
        case "scrollview": return .scrollView(ScrollViewProperties())
        case "rectangle": return .shape(ShapeProperties(shapeType: .rectangle))
        case "circle": return .shape(ShapeProperties(shapeType: .circle))
        case "spacer": return .spacer
        case "divider": return .divider

        case "text":
            try missing("content")
            return .text(TextProperties(content: ""))

        case "image":
            try missing("imageURL, imageName or systemImage")
            return .image(ImageProperties())

        case "button":
            try missing("label")
            return .button(ButtonProperties(label: "Button"))

        default:
            return try unknown(typeString, context: context, codingPath: codingPath)
        }
    }

    private static func unknown(
        _ typeString: String,
        context: JUNDecodingContext,
        codingPath: [CodingKey]
    ) throws -> ComponentProperties {
        // A warning, not an error: an unrecognised type usually means the document was
        // produced against a newer version of the specification than this renderer implements,
        // and rejecting it would make every server-side addition wait for an app release.
        context.warn("unknown component type '\(typeString)'", at: codingPath)

        if context.options.unknownComponents == .fail {
            throw JUNParseError.unsupportedComponent(
                type: typeString,
                path: JUNPath.describe(codingPath)
            )
        }

        return .unknown(typeString)
    }
}

// MARK: - Conformances

extension UIComponent: Codable { }

extension UIComponent: Identifiable { }

extension UIComponent: Equatable {
    /// Compares structure, ignoring ``id``.
    ///
    /// Identifiers are generated per decode when the document omits them, so including them
    /// would mean two decodes of the same document never compared equal — which is the one
    /// case the conformance is wanted for.
    public static func == (lhs: UIComponent, rhs: UIComponent) -> Bool {
        lhs.type == rhs.type && lhs.children == rhs.children
    }
}

extension UIComponent: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type.typeString)
        hasher.combine(children)
    }
}

// MARK: - Internal Signals

/// Signals that a component could not be built and its diagnostic has already been recorded.
///
/// Caught by the parent's child loop, which drops the component and carries on with its
/// siblings.
struct JUNComponentUnrenderable: Error { }

/// Consumes one element of an unkeyed container without interpreting it, so decoding can step
/// past a malformed child.
private struct SkippedElement: Decodable {
    init(from decoder: Decoder) throws { }
}
