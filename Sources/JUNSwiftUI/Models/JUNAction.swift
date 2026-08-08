import Foundation

/// An intent named by a JUN document and interpreted by the host application.
///
/// A document can only *name* an action. Nothing happens unless the host installs a handler
/// with ``SwiftUI/View/junActionHandler(_:)`` and implements the name, which is what keeps a
/// document fetched from a server from being able to cause an effect on its own.
public struct JUNAction: Hashable, Sendable {
    /// The action identifier, for example `"addToCart"`.
    public let name: String

    /// Parameters passed through to the host application, untouched.
    public let params: [String: JUNValue]

    public init(name: String, params: [String: JUNValue] = [:]) {
        self.name = name
        self.params = params
    }

    /// Whether the name is in the dotted namespace the specification reserves for itself.
    ///
    /// No reserved actions are defined in JUN v1.2. Implementations forward them to the host
    /// unchanged rather than erroring, so a later version can define standard actions without
    /// breaking clients built against this one.
    public var isReserved: Bool {
        name.contains(".")
    }
}

// MARK: - Codable

extension JUNAction: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, params
    }

    /// Decodes either the object form or the string shorthand.
    ///
    /// `"checkout"` is exactly equivalent to `{"name": "checkout", "params": {}}`.
    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let name = try? single.decode(String.self) {
            guard !name.isEmpty else {
                throw DecodingError.dataCorruptedError(
                    in: single,
                    debugDescription: "Action name must not be empty"
                )
            }
            self.init(name: name)
            return
        }

        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        let name: String = try container.decode(String.self, forKey: .name)

        guard !name.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .name,
                in: container,
                debugDescription: "Action name must not be empty"
            )
        }

        self.init(
            name: name,
            params: try container.decodeIfPresent([String: JUNValue].self, forKey: .params) ?? [:]
        )
    }

    /// Encodes to the string shorthand when there are no parameters.
    public func encode(to encoder: Encoder) throws {
        guard !params.isEmpty else {
            var container: SingleValueEncodingContainer = encoder.singleValueContainer()
            try container.encode(name)
            return
        }

        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(params, forKey: .params)
    }
}
