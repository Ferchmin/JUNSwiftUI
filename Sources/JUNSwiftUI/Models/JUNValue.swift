import Foundation

/// A JSON scalar carried in an action's parameters.
///
/// JUN v1.2 restricts action parameters to scalars. Nested objects and arrays are rejected,
/// which keeps unpacking on the host side free of schema guesswork. The restriction can be
/// relaxed in a later version without breaking existing documents.
public enum JUNValue: Hashable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
}

// MARK: - Convenience Accessors

public extension JUNValue {
    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var doubleValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    var intValue: Int? {
        if case .number(let value) = self { return Int(value) }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    var isNull: Bool {
        if case .null = self { return true }
        return false
    }
}

// MARK: - Codable

extension JUNValue: Codable {
    public init(from decoder: Decoder) throws {
        let container: SingleValueDecodingContainer = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
            return
        }

        // Bool is attempted before Double: JSONDecoder does not decode `1` as a Bool, so the
        // order only matters for making the intent explicit.
        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Action parameters must be a string, number, boolean, or null"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container: SingleValueEncodingContainer = encoder.singleValueContainer()

        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

// MARK: - Literal Conveniences

extension JUNValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension JUNValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension JUNValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension JUNValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}
