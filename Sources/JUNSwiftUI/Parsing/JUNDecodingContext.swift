import Foundation

/// Carries parse options and accumulates diagnostics across a single decode.
///
/// Passed to the decoder through `userInfo`, because `Decodable` gives no other way to thread
/// state through a recursive decode.
final class JUNDecodingContext {
    let options: JUNParseOptions

    private(set) var diagnostics: [JUNDiagnostic] = []
    private var nodeCount: Int = 0

    init(options: JUNParseOptions = .default) {
        self.options = options
    }

    // MARK: - Diagnostics

    func warn(_ message: String, at codingPath: [CodingKey]) {
        diagnostics.append(
            JUNDiagnostic(severity: .warning, path: JUNPath.describe(codingPath), message: message)
        )
    }

    func fail(_ message: String, at codingPath: [CodingKey]) {
        diagnostics.append(
            JUNDiagnostic(severity: .error, path: JUNPath.describe(codingPath), message: message)
        )
    }

    // MARK: - Resource Limits

    /// Counts a component and enforces the depth and node limits.
    ///
    /// Depth is derived from the coding path: each level of nesting contributes one `children`
    /// key, so counting those gives the component's depth without threading a counter through
    /// the decode.
    func registerComponent(at codingPath: [CodingKey]) throws {
        nodeCount += 1

        if nodeCount > options.maxNodes {
            throw JUNParseError.nodeLimitExceeded(limit: options.maxNodes)
        }

        let depth: Int = codingPath.reduce(into: 0) { total, key in
            if key.stringValue == UIComponent.childrenKeyName {
                total += 1
            }
        }

        if depth > options.maxDepth {
            throw JUNParseError.depthLimitExceeded(
                limit: options.maxDepth,
                path: JUNPath.describe(codingPath)
            )
        }
    }
}

// MARK: - Decoder Access

extension CodingUserInfoKey {
    static let junDecodingContext: CodingUserInfoKey = CodingUserInfoKey(
        rawValue: "com.jun.swiftui.decodingContext"
    )!
}

extension Decoder {
    /// The context installed by ``JSONLoader``.
    ///
    /// Decoding a `UIComponent` with a bare `JSONDecoder` still works — it just parses with
    /// default options and discards diagnostics, since there is nowhere to put them.
    var junContext: JUNDecodingContext {
        (userInfo[.junDecodingContext] as? JUNDecodingContext) ?? JUNDecodingContext()
    }
}

// MARK: - Lenient Decoding

extension KeyedDecodingContainer {
    /// Decodes an optional property, distinguishing "absent" from "present but wrong type".
    ///
    /// An absent key is silently `nil`, which is what optional properties mean. A key that is
    /// present but holds the wrong kind of value is a producer bug, so it records an error
    /// diagnostic and — under ``JUNParseOptions/InvalidValuePolicy/fail`` — rejects the
    /// document.
    func junDecode<T: Decodable>(
        _ type: T.Type,
        forKey key: Key,
        _ context: JUNDecodingContext
    ) throws -> T? {
        guard contains(key) else { return nil }

        do {
            if try decodeNil(forKey: key) { return nil }
            return try decode(T.self, forKey: key)
        } catch let error as JUNParseError {
            throw error
        } catch {
            let path: [CodingKey] = JUNPath.appending(key, to: codingPath)
            let message: String = "expected \(T.self)"

            context.fail(message, at: path)

            if context.options.invalidValues == .fail {
                throw JUNParseError.invalidValue(path: JUNPath.describe(path), message: message)
            }

            return nil
        }
    }

    /// Decodes a required property, recording a diagnostic and returning `nil` when it is
    /// missing or malformed.
    func junDecodeRequired<T: Decodable>(
        _ type: T.Type,
        forKey key: Key,
        _ context: JUNDecodingContext
    ) throws -> T? {
        guard contains(key) else {
            let path: [CodingKey] = JUNPath.appending(key, to: codingPath)
            let message: String = "missing required property '\(key.stringValue)'"

            context.fail(message, at: path)

            if context.options.invalidValues == .fail {
                throw JUNParseError.invalidValue(path: JUNPath.describe(path), message: message)
            }

            return nil
        }

        return try junDecode(T.self, forKey: key, context)
    }
}
