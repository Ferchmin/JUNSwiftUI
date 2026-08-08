import Foundation

/// A failure that rejects the whole document.
///
/// These are deliberately few. Most problems produce a ``JUNDiagnostic`` and leave the rest of
/// the document renderable; a `JUNParseError` is thrown only when there is nothing sensible to
/// render, or when a resource limit makes continuing unsafe, or when the caller asked for
/// strict parsing.
public enum JUNParseError: Error, Hashable, Sendable {
    /// Nesting exceeded ``JUNParseOptions/maxDepth``.
    case depthLimitExceeded(limit: Int, path: String)

    /// The component count exceeded ``JUNParseOptions/maxNodes``.
    case nodeLimitExceeded(limit: Int)

    /// An unrecognised component type, under ``JUNParseOptions/UnknownComponentPolicy/fail``.
    case unsupportedComponent(type: String, path: String)

    /// A malformed value, under ``JUNParseOptions/InvalidValuePolicy/fail``.
    case invalidValue(path: String, message: String)

    /// The root component itself could not be understood, so there is nothing to render.
    case unrenderableRoot(diagnostics: [JUNDiagnostic])
}

extension JUNParseError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .depthLimitExceeded(let limit, let path):
            return "Document nests deeper than \(limit) levels at \(path)"

        case .nodeLimitExceeded(let limit):
            return "Document contains more than \(limit) components"

        case .unsupportedComponent(let type, let path):
            return "Unsupported component type '\(type)' at \(path)"

        case .invalidValue(let path, let message):
            return "Invalid value at \(path): \(message)"

        case .unrenderableRoot(let diagnostics):
            let detail: String = diagnostics
                .filter { $0.severity == .error }
                .map(\.description)
                .joined(separator: "; ")
            return detail.isEmpty
                ? "The document's root component could not be rendered"
                : "The document's root component could not be rendered: \(detail)"
        }
    }
}
