import Testing
import Foundation
@testable import JUNSwiftUI

@Suite("UIComponent Tests")
struct ComponentTests {

    @Test("UIComponent can be decoded from JSON")
    func testComponentDecoding() throws {
        let json: String = """
        {
            "type": "vstack",
            "properties": {
                "spacing": 10,
                "alignment": "center"
            },
            "children": [
                {
                    "type": "text",
                    "properties": {
                        "content": "Hello",
                        "fontSize": 20
                    }
                }
            ]
        }
        """

        let component: UIComponent = try JSONLoader.loadFromString(json)

        // Check root component is vstack
        guard case .layout(let layoutProps) = component.type else {
            Issue.record("Expected layout type")
            return
        }

        #expect(layoutProps.layoutType == .vstack)
        #expect(layoutProps.spacing == 10)
        #expect(layoutProps.alignment == "center")

        // Check children
        #expect(component.children?.count == 1)

        guard let firstChild = component.children?.first,
              case .text(let textProps) = firstChild.type else {
            Issue.record("Expected text child")
            return
        }

        #expect(textProps.content == "Hello")
        #expect(textProps.fontSize == 20)
    }

    @Test("Text component decodes correctly")
    func testTextComponent() throws {
        let json: String = """
        {
            "type": "text",
            "properties": {
                "content": "Test",
                "fontSize": 16,
                "fontWeight": "bold",
                "foregroundColor": "blue"
            }
        }
        """

        let component: UIComponent = try JSONLoader.loadFromString(json)

        guard case .text(let props) = component.type else {
            Issue.record("Expected text type")
            return
        }

        #expect(props.content == "Test")
        #expect(props.fontSize == 16)
        #expect(props.fontWeight == "bold")
        #expect(props.common.foregroundColor == "blue")
    }

    @Test("Image component decodes correctly")
    func testImageComponent() throws {
        let json: String = """
        {
            "type": "image",
            "properties": {
                "imageURL": "https://example.com/image.jpg",
                "resizable": true,
                "width": 40,
                "height": 40,
                "foregroundColor": "yellow"
            }
        }
        """

        let component: UIComponent = try JSONLoader.loadFromString(json)

        guard case .image(let props) = component.type else {
            Issue.record("Expected image type")
            return
        }

        #expect(props.imageURL == "https://example.com/image.jpg")
        #expect(props.resizable == true)
        #expect(props.common.width == 40)
        #expect(props.common.height == 40)
        #expect(props.common.foregroundColor == "yellow")
    }

    @Test("Font property decodes correctly in text component")
    func testFontProperty() throws {
        let json: String = """
        {
            "type": "text",
            "properties": {
                "content": "Custom Font Text",
                "fontSize": 24,
                "fontWeight": "bold",
                "font": "Helvetica",
                "foregroundColor": "blue"
            }
        }
        """

        let component: UIComponent = try JSONLoader.loadFromString(json)

        guard case .text(let props) = component.type else {
            Issue.record("Expected text type")
            return
        }

        #expect(props.content == "Custom Font Text")
        #expect(props.fontSize == 24)
        #expect(props.fontWeight == "bold")
        #expect(props.common.font == "Helvetica")
        #expect(props.common.foregroundColor == "blue")
    }

    @Test("Font property works with button component")
    func testFontPropertyOnButton() throws {
        let json: String = """
        {
            "type": "button",
            "properties": {
                "label": "Custom Font Button",
                "font": "Georgia",
                "backgroundColor": "blue",
                "foregroundColor": "white"
            }
        }
        """

        let component: UIComponent = try JSONLoader.loadFromString(json)

        guard case .button(let props) = component.type else {
            Issue.record("Expected button type")
            return
        }

        #expect(props.label == "Custom Font Button")
        #expect(props.common.font == "Georgia")
        #expect(props.common.backgroundColor == "blue")
        #expect(props.common.foregroundColor == "white")
    }

    @Test("Font property is optional")
    func testFontPropertyOptional() throws {
        let json: String = """
        {
            "type": "text",
            "properties": {
                "content": "System Font Text",
                "fontSize": 18
            }
        }
        """

        let component: UIComponent = try JSONLoader.loadFromString(json)

        guard case .text(let props) = component.type else {
            Issue.record("Expected text type")
            return
        }

        #expect(props.content == "System Font Text")
        #expect(props.fontSize == 18)
        #expect(props.common.font == nil)
    }
}
