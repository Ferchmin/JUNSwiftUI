import Foundation

/// Controls how strictly a JUN document is parsed.
///
/// The defaults implement what the specification requires of a renderer that consumes
/// documents from a server: degrade on anything that looks like a newer version of the
/// format, report anything that looks like a bug, and refuse anything unbounded.
public struct JUNParseOptions: Hashable, Sendable {
    /// What to do with a component whose `type` this version does not recognise.
    public enum UnknownComponentPolicy: Hashable, Sendable {
        /// Drop the component, keep its siblings, record a warning. Required default: a
        /// client that rejects a document containing one unfamiliar component forces every
        /// server-side addition to wait for a coordinated client release.
        case skip

        /// Keep the component and render a visible placeholder in its place. Useful while
        /// developing against a newer server than the app supports.
        case placeholder

        /// Reject the document.
        case fail
    }

    /// What to do with a property that is present but holds the wrong kind of value.
    public enum InvalidValuePolicy: Hashable, Sendable {
        /// Fall back to the property's default and record an error diagnostic.
        case useDefault

        /// Reject the document.
        case fail
    }

    public var unknownComponents: UnknownComponentPolicy
    public var invalidValues: InvalidValuePolicy

    /// Maximum nesting depth. Exceeding it rejects the document outright — this is protection
    /// against untrusted input, not a stylistic preference, so it is not affected by the
    /// policies above.
    public var maxDepth: Int

    /// Maximum total component count. Rejects the document when exceeded.
    public var maxNodes: Int

    public init(
        unknownComponents: UnknownComponentPolicy = .skip,
        invalidValues: InvalidValuePolicy = .useDefault,
        maxDepth: Int = 64,
        maxNodes: Int = 10_000
    ) {
        self.unknownComponents = unknownComponents
        self.invalidValues = invalidValues
        self.maxDepth = maxDepth
        self.maxNodes = maxNodes
    }

    /// Lenient rendering with full reporting. Use this in an app.
    public static let `default`: JUNParseOptions = JUNParseOptions()

    /// Fails on anything the specification calls malformed. Use this in tests and in build
    /// pipelines, where a document that only *mostly* parses should not pass.
    public static let strict: JUNParseOptions = JUNParseOptions(
        unknownComponents: .fail,
        invalidValues: .fail
    )
}
