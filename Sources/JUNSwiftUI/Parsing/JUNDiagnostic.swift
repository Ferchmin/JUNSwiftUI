import Foundation

/// A problem found while parsing a JUN document, identified by where in the document it was.
///
/// Diagnostics are how JUNSwiftUI keeps a producer-side bug from turning into a blank screen
/// with no explanation. Parsing stays lenient — everything that could be understood is still
/// rendered — but nothing is discarded silently.
public struct JUNDiagnostic: Hashable, Sendable {
    public enum Severity: String, Hashable, Sendable {
        /// The document is valid but something was ignored, typically a forward-compatibility
        /// case such as an unknown component type or an unrecognised enum value.
        case warning

        /// The document is malformed: a value of the wrong type, or a missing required
        /// property. This is a bug in whatever produced the document.
        case error
    }

    public let severity: Severity

    /// Location within the document, for example `children[3].properties.imageURL`.
    public let path: String

    public let message: String

    public init(severity: Severity, path: String, message: String) {
        self.severity = severity
        self.path = path
        self.message = message
    }
}

extension JUNDiagnostic: CustomStringConvertible {
    public var description: String {
        "\(severity.rawValue) at \(path): \(message)"
    }
}

/// Renders a `Decoder`'s coding path as a readable document location.
enum JUNPath {
    static func describe(_ codingPath: [CodingKey]) -> String {
        var result: String = ""

        for key in codingPath {
            if let index = key.intValue {
                result += "[\(index)]"
            } else if result.isEmpty {
                result += key.stringValue
            } else {
                result += ".\(key.stringValue)"
            }
        }

        return result.isEmpty ? "<root>" : result
    }

    static func appending(_ key: CodingKey, to codingPath: [CodingKey]) -> [CodingKey] {
        var result: [CodingKey] = codingPath
        result.append(key)
        return result
    }
}
