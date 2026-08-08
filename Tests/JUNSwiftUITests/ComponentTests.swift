import Testing
import Foundation
@testable import JUNSwiftUI

@Suite("Component decoding")
struct ComponentTests {

    @Test("A nested document decodes into the expected tree")
    func nestedDocument() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        {
            "type": "vstack",
            "properties": { "spacing": 10, "alignment": "center" },
            "children": [
                { "type": "text", "properties": { "content": "Hello", "fontSize": 20 } }
            ]
        }
        """)

        guard case .layout(let layout) = document.root.type else {
            Issue.record("Expected a layout root")
            return
        }

        #expect(layout.layoutType == .vstack)
        #expect(layout.spacing == 10)
        #expect(layout.alignment == "center")
        #expect(document.root.children?.count == 1)
        #expect(document.diagnostics.isEmpty)

        guard let child = document.root.children?.first, case .text(let text) = child.type else {
            Issue.record("Expected a text child")
            return
        }

        #expect(text.content == "Hello")
        #expect(text.fontSize == 20)
    }

    @Test("Text decodes its own and its universal properties")
    func textProperties() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        {
            "type": "text",
            "properties": {
                "content": "Test",
                "fontSize": 16,
                "fontWeight": "bold",
                "font": "Georgia",
                "foregroundColor": "blue"
            }
        }
        """)

        guard case .text(let props) = document.root.type else {
            Issue.record("Expected text")
            return
        }

        #expect(props.content == "Test")
        #expect(props.fontWeight == "bold")
        #expect(props.common.font == "Georgia")
        #expect(props.common.foregroundColor == "blue")
        #expect(document.diagnostics.isEmpty)
    }

    @Test("Components without a properties object still decode")
    func missingPropertiesObject() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        { "type": "vstack", "children": [{ "type": "spacer" }, { "type": "divider" }] }
        """)

        #expect(document.root.children?.count == 2)
        #expect(document.diagnostics.isEmpty)
    }

    @Test("A component type is matched case-insensitively")
    func caseInsensitiveType() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        { "type": "ScrollView", "properties": { "axis": "horizontal" } }
        """)

        guard case .scrollView(let props) = document.root.type else {
            Issue.record("Expected scrollView")
            return
        }

        #expect(props.axis == "horizontal")
    }
}

// MARK: -

@Suite("Images")
struct ImageTests {

    @Test("Each of the three sources decodes", arguments: [
        (#"{"imageURL": "https://example.com/a.jpg"}"#, ImageSource.url("https://example.com/a.jpg")),
        (#"{"imageName": "hero"}"#, ImageSource.name("hero")),
        (#"{"systemImage": "star.fill"}"#, ImageSource.system("star.fill"))
    ])
    func imageSources(json: String, expected: ImageSource) throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        { "type": "image", "properties": \(json) }
        """)

        guard case .image(let props) = document.root.type else {
            Issue.record("Expected image")
            return
        }

        #expect(props.source == expected)
        #expect(document.diagnostics.isEmpty)
    }

    @Test("An image with no source is reported and renders a placeholder")
    func imageWithoutSource() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        { "type": "image", "properties": { "resizable": true } }
        """)

        guard case .image(let props) = document.root.type else {
            Issue.record("Expected image")
            return
        }

        #expect(props.source == nil)
        #expect(document.hasErrors)
    }

    @Test("An image with two sources is reported")
    func ambiguousImageSource() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        { "type": "image", "properties": { "imageName": "hero", "systemImage": "star" } }
        """)

        #expect(document.hasErrors)
    }

    @Test("Strict parsing rejects an image with no source")
    func strictRejectsSourcelessImage() {
        #expect(throws: JUNParseError.self) {
            try JSONLoader.loadFromString(
                #"{ "type": "image", "properties": { "resizable": true } }"#,
                options: .strict
            )
        }
    }
}

// MARK: -

@Suite("Actions")
struct ActionTests {

    @Test("The string shorthand is equivalent to an action with no parameters")
    func stringShorthand() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        { "type": "button", "properties": { "label": "Go", "action": "checkout" } }
        """)

        guard case .button(let props) = document.root.type else {
            Issue.record("Expected button")
            return
        }

        #expect(props.action == JUNAction(name: "checkout"))
        #expect(props.action?.params.isEmpty == true)
    }

    @Test("The object form carries scalar parameters")
    func objectForm() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        {
            "type": "button",
            "properties": {
                "label": "Add",
                "action": {
                    "name": "addToCart",
                    "params": { "productId": "SKU-42", "qty": 2, "gift": true, "note": null }
                }
            }
        }
        """)

        guard case .button(let props) = document.root.type, let action = props.action else {
            Issue.record("Expected a button with an action")
            return
        }

        #expect(action.name == "addToCart")
        #expect(action.params["productId"]?.stringValue == "SKU-42")
        #expect(action.params["qty"]?.intValue == 2)
        #expect(action.params["gift"]?.boolValue == true)
        #expect(action.params["note"]?.isNull == true)
    }

    @Test("A button without an action decodes")
    func actionIsOptional() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        { "type": "button", "properties": { "label": "Inert" } }
        """)

        guard case .button(let props) = document.root.type else {
            Issue.record("Expected button")
            return
        }

        #expect(props.action == nil)
        #expect(document.diagnostics.isEmpty)
    }

    @Test("Dotted names are recognised as reserved but still delivered")
    func reservedNames() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        { "type": "button", "properties": { "label": "Open", "action": "jun.openURL" } }
        """)

        guard case .button(let props) = document.root.type else {
            Issue.record("Expected button")
            return
        }

        #expect(props.action?.isReserved == true)
        #expect(document.diagnostics.isEmpty, "A reserved action must not be treated as an error")
    }

    @Test("Nested parameter values are rejected")
    func nestedParamsRejected() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        {
            "type": "button",
            "properties": {
                "label": "Go",
                "action": { "name": "x", "params": { "nested": { "a": 1 } } }
            }
        }
        """)

        #expect(document.hasErrors)
    }
}

// MARK: -

@Suite("The removed legacy dialect")
struct LegacyDialectTests {

    @Test("buttonLabel is no longer accepted")
    func buttonLabel() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        { "type": "button", "properties": { "buttonLabel": "Get Started" } }
        """)

        guard case .button(let props) = document.root.type else {
            Issue.record("Expected button")
            return
        }

        #expect(props.label == "Button", "The unspecified alias must not populate the label")
        #expect(document.hasErrors, "A missing required property must be reported")
    }

    @Test("scrollAxis is no longer accepted")
    func scrollAxis() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        { "type": "scrollView", "properties": { "scrollAxis": "horizontal" } }
        """)

        guard case .scrollView(let props) = document.root.type else {
            Issue.record("Expected scrollView")
            return
        }

        #expect(props.axis == nil, "The unspecified alias must not set the axis")
    }
}

// MARK: -

@Suite("Diagnostics")
struct DiagnosticTests {

    @Test("A property of the wrong type is reported, with its location")
    func wrongType() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        {
            "type": "vstack",
            "children": [
                { "type": "text", "properties": { "content": "ok" } },
                { "type": "text", "properties": { "content": "bad", "fontSize": "20" } }
            ]
        }
        """)

        #expect(document.hasErrors)
        #expect(document.errors.first?.path.contains("fontSize") == true)
        #expect(document.root.children?.count == 2, "The rest of the component still renders")
    }

    @Test("A missing required property is reported")
    func missingRequired() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        { "type": "text", "properties": { "fontSize": 12 } }
        """)

        #expect(document.hasErrors)
        #expect(document.errors.first?.message.contains("content") == true)
    }

    @Test("A malformed child does not take out its siblings")
    func siblingIsolation() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        {
            "type": "vstack",
            "children": [
                { "type": "text", "properties": { "content": "first" } },
                42,
                { "type": "text", "properties": { "content": "second" } },
                { "properties": { "content": "no type" } },
                { "type": "text", "properties": { "content": "third" } }
            ]
        }
        """)

        #expect(document.root.children?.count == 3, "Three well-formed siblings must survive")
        #expect(document.errors.count >= 2)
    }

    @Test("Diagnostic paths identify where the problem is")
    func diagnosticPaths() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        {
            "type": "vstack",
            "children": [
                { "type": "vstack", "children": [
                    { "type": "image", "properties": { "imageURL": 7 } }
                ]}
            ]
        }
        """)

        let path: String = try #require(document.errors.first?.path)
        #expect(path.contains("children[0]"))
        #expect(path.contains("imageURL"))
    }

    @Test("Strict parsing turns a malformed value into a thrown error")
    func strictThrows() {
        #expect(throws: JUNParseError.self) {
            try JSONLoader.loadFromString(
                #"{ "type": "text", "properties": { "content": "x", "fontSize": "20" } }"#,
                options: .strict
            )
        }
    }
}

// MARK: -

@Suite("Unknown components")
struct UnknownComponentTests {

    private static let documentWithUnknownChild: String = """
    {
        "type": "vstack",
        "children": [
            { "type": "text", "properties": { "content": "known" } },
            { "type": "tabView", "properties": { "padding": 4 } }
        ]
    }
    """

    @Test("The default policy drops an unknown component and warns")
    func skip() throws {
        let document: JUNDocument = try JSONLoader.loadFromString(Self.documentWithUnknownChild)

        #expect(document.root.children?.count == 1)
        #expect(document.hasErrors == false, "An unknown type is a warning, not an error")
        #expect(document.diagnostics.contains { $0.message.contains("tabView") })
    }

    @Test("The placeholder policy keeps it")
    func placeholder() throws {
        let document: JUNDocument = try JSONLoader.loadFromString(
            Self.documentWithUnknownChild,
            options: JUNParseOptions(unknownComponents: .placeholder)
        )

        #expect(document.root.children?.count == 2)
    }

    @Test("The fail policy rejects the document")
    func fail() {
        #expect(throws: JUNParseError.self) {
            try JSONLoader.loadFromString(
                Self.documentWithUnknownChild,
                options: JUNParseOptions(unknownComponents: .fail)
            )
        }
    }

    @Test("An unknown type behaves the same with and without a properties object")
    func consistentRegardlessOfShape() throws {
        let withProperties: JUNDocument = try JSONLoader.loadFromString("""
        { "type": "vstack", "children": [{ "type": "gauge", "properties": { "padding": 1 } }] }
        """)

        let withoutProperties: JUNDocument = try JSONLoader.loadFromString("""
        { "type": "vstack", "children": [{ "type": "gauge" }] }
        """)

        #expect(withProperties.root.children?.count == 0)
        #expect(withoutProperties.root.children?.count == 0)
        #expect(withProperties.diagnostics.count == withoutProperties.diagnostics.count)
    }

    @Test("An unknown root has nothing to degrade to and is rejected")
    func unknownRoot() {
        #expect(throws: JUNParseError.self) {
            try JSONLoader.loadFromString(#"{ "type": "tabView" }"#)
        }
    }
}

// MARK: -

@Suite("Resource limits")
struct ResourceLimitTests {

    private func nested(depth: Int) -> String {
        var json: String = #"{"type":"text","properties":{"content":"leaf"}}"#
        for _ in 0..<depth {
            json = #"{"type":"vstack","children":["# + json + "]}"
        }
        return json
    }

    @Test("Nesting within the limit is accepted")
    func withinDepthLimit() throws {
        let document: JUNDocument = try JSONLoader.loadFromString(
            nested(depth: 8),
            options: JUNParseOptions(maxDepth: 16)
        )

        #expect(document.diagnostics.isEmpty)
    }

    @Test("Nesting beyond the limit is rejected outright")
    func beyondDepthLimit() {
        #expect(throws: JUNParseError.self) {
            try JSONLoader.loadFromString(
                nested(depth: 40),
                options: JUNParseOptions(maxDepth: 16)
            )
        }
    }

    @Test("A document with too many components is rejected")
    func nodeLimit() {
        let children: String = Array(
            repeating: #"{"type":"text","properties":{"content":"x"}}"#,
            count: 50
        ).joined(separator: ",")

        #expect(throws: JUNParseError.self) {
            try JSONLoader.loadFromString(
                #"{"type":"vstack","children":["# + children + "]}",
                options: JUNParseOptions(maxNodes: 10)
            )
        }
    }

    @Test("Limits apply regardless of the leniency policies")
    func limitsIgnorePolicies() {
        #expect(throws: JUNParseError.self) {
            try JSONLoader.loadFromString(
                nested(depth: 40),
                options: JUNParseOptions(unknownComponents: .skip, invalidValues: .useDefault, maxDepth: 4)
            )
        }
    }
}

// MARK: -

@Suite("Round trips")
struct RoundTripTests {

    @Test("Encoding and decoding again produces an equal tree")
    func roundTrip() throws {
        let original: JUNDocument = try JSONLoader.loadFromString("""
        {
            "type": "vstack",
            "properties": { "spacing": 12, "padding": 16, "backgroundColor": "#F0F0F0" },
            "children": [
                { "type": "text", "properties": { "content": "Title", "fontSize": 24, "fontWeight": "bold" } },
                { "type": "image", "properties": { "systemImage": "star.fill", "width": 24 } },
                { "type": "button", "properties": {
                    "label": "Buy",
                    "action": { "name": "buy", "params": { "sku": "42", "qty": 1 } }
                }},
                { "type": "rectangle", "properties": { "width": 40, "height": 40, "foregroundColor": "red" } },
                { "type": "spacer" },
                { "type": "divider" }
            ]
        }
        """)

        let encoded: Data = try JSONEncoder().encode(original.root)
        let decoded: JUNDocument = try JSONLoader.loadFromData(encoded)

        #expect(decoded.root == original.root)
        #expect(decoded.diagnostics.isEmpty, "Re-encoded output must itself be a valid document")
    }

    @Test("Equality ignores generated identifiers")
    func equalityIgnoresIdentifiers() throws {
        let json: String = #"{"type":"text","properties":{"content":"same"}}"#

        let first: JUNDocument = try JSONLoader.loadFromString(json)
        let second: JUNDocument = try JSONLoader.loadFromString(json)

        #expect(first.root.id != second.root.id)
        #expect(first.root == second.root)
        #expect(first.root.hashValue == second.root.hashValue)
    }

    @Test("An action with no parameters encodes back to the string shorthand")
    func actionShorthandRoundTrip() throws {
        let document: JUNDocument = try JSONLoader.loadFromString("""
        { "type": "button", "properties": { "label": "Go", "action": "checkout" } }
        """)

        let encoded: String = try #require(
            String(data: try JSONEncoder().encode(document.root), encoding: .utf8)
        )

        #expect(encoded.contains("\"action\":\"checkout\""))
    }
}

// MARK: -

@Suite("Loading")
struct LoaderTests {

    @Test("A remote URL is refused by the synchronous file loader")
    func remoteURLRejected() {
        let url: URL = URL(string: "https://example.com/screen.json")!

        #expect(throws: JSONLoaderError.self) {
            try JSONLoader.loadFromFile(url)
        }
    }

    @Test("Invalid JSON reports a load failure")
    func invalidJSON() {
        #expect(throws: JSONLoaderError.self) {
            try JSONLoader.loadFromString(#"{"type": "vstack",}"#)
        }
    }
}

// MARK: -

@Suite("Canonical JUN examples")
struct CanonicalExampleTests {

    /// The examples committed by `Scripts/sync-examples.sh`, which are the JUN repository's own
    /// documents. Rendering the specification's examples correctly is what "reference
    /// implementation" has to mean.
    private static var exampleURLs: [URL] {
        get throws {
            let repositoryRoot: URL = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()   // JUNSwiftUITests
                .deletingLastPathComponent()   // Tests
                .deletingLastPathComponent()   // repository root

            let directory: URL = repositoryRoot
                .appendingPathComponent("Example/JUNSwiftUIApp/Resources/Examples")

            return try FileManager.default
                .contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
        }
    }

    @Test("Every canonical example is present")
    func examplesArePresent() throws {
        #expect(try Self.exampleURLs.count >= 6)
    }

    @Test("Every canonical example parses strictly, with no diagnostics")
    func examplesParseStrictly() throws {
        for url in try Self.exampleURLs {
            let data: Data = try Data(contentsOf: url)
            let document: JUNDocument = try JSONLoader.loadFromData(data, options: .strict)

            #expect(
                document.diagnostics.isEmpty,
                "\(url.lastPathComponent): \(document.diagnostics.map(\.description))"
            )
        }
    }

    @Test("Every canonical example survives a round trip")
    func examplesRoundTrip() throws {
        for url in try Self.exampleURLs {
            let original: JUNDocument = try JSONLoader.loadFromData(try Data(contentsOf: url))
            let reencoded: JUNDocument = try JSONLoader.loadFromData(try JSONEncoder().encode(original.root))

            #expect(reencoded.root == original.root, "\(url.lastPathComponent) did not round trip")
        }
    }
}
