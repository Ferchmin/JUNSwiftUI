import Testing
import Foundation
@testable import JSONToSwiftUIPOCLib

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
                "imageName": "star.fill",
                "imageWidth": 40,
                "imageHeight": 40,
                "foregroundColor": "yellow"
            }
        }
        """

        let component: UIComponent = try JSONLoader.loadFromString(json)

        guard case .image(let props) = component.type else {
            Issue.record("Expected image type")
            return
        }

        #expect(props.imageName == "star.fill")
        #expect(props.imageWidth == 40)
        #expect(props.imageHeight == 40)
        #expect(props.common.foregroundColor == "yellow")
    }
}
