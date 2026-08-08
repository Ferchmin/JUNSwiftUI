import Foundation

/// A parsed JUN document: the component tree, plus everything that went wrong producing it.
///
/// The diagnostics are the point. A lenient parser that reports nothing turns a producer-side
/// bug into a blank screen with no diagnosis, so parsing never discards a problem — it renders
/// what it understood and hands back the rest.
///
/// In an app, forward ``diagnostics`` to whatever you use for telemetry. That is how the
/// server that produced a broken document finds out, from the field, that it is broken.
public struct JUNDocument: Hashable, Sendable {
    public let root: UIComponent
    public let diagnostics: [JUNDiagnostic]

    public init(root: UIComponent, diagnostics: [JUNDiagnostic] = []) {
        self.root = root
        self.diagnostics = diagnostics
    }

    /// Diagnostics indicating the document was malformed, as opposed to merely newer than
    /// this version of the renderer.
    public var errors: [JUNDiagnostic] {
        diagnostics.filter { $0.severity == .error }
    }

    public var hasErrors: Bool {
        diagnostics.contains { $0.severity == .error }
    }
}
