import Foundation
import os

/// Loads and decodes JUN documents.
public enum JSONLoader {

    // MARK: - Loading

    /// Decodes a JUN document from data.
    public static func loadFromData(
        _ data: Data,
        options: JUNParseOptions = .default
    ) throws -> JUNDocument {
        try decode(data, options: options)
    }

    /// Decodes a JUN document from a JSON string.
    public static func loadFromString(
        _ jsonString: String,
        options: JUNParseOptions = .default
    ) throws -> JUNDocument {
        guard let data = jsonString.data(using: .utf8) else {
            throw JSONLoaderError.invalidString
        }

        return try decode(data, options: options)
    }

    /// Decodes a JUN document from a JSON file in a bundle.
    public static func loadFromBundle(
        filename: String,
        bundle: Bundle = .main,
        options: JUNParseOptions = .default
    ) throws -> JUNDocument {
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            throw JSONLoaderError.fileNotFound(filename)
        }

        return try decode(try Data(contentsOf: url), options: options)
    }

    /// Decodes a JUN document from a local file.
    ///
    /// Rejects non-file URLs deliberately. Reading a remote URL synchronously blocks whatever
    /// thread the caller happens to be on — usually the main one — with no timeout and no
    /// cancellation, so remote documents go through ``load(from:session:options:)`` instead.
    public static func loadFromFile(
        _ url: URL,
        options: JUNParseOptions = .default
    ) throws -> JUNDocument {
        guard url.isFileURL else {
            throw JSONLoaderError.notAFileURL(url)
        }

        return try decode(try Data(contentsOf: url), options: options)
    }

    /// Fetches and decodes a JUN document over the network.
    public static func load(
        from url: URL,
        session: URLSession = .shared,
        options: JUNParseOptions = .default
    ) async throws -> JUNDocument {
        let (data, response): (Data, URLResponse) = try await session.data(from: url)

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw JSONLoaderError.httpError(statusCode: http.statusCode, url: url)
        }

        return try decode(data, options: options)
    }

    // MARK: - Private Helpers

    private static func decode(_ data: Data, options: JUNParseOptions) throws -> JUNDocument {
        let context: JUNDecodingContext = JUNDecodingContext(options: options)
        let decoder: JSONDecoder = JSONDecoder()
        decoder.userInfo[.junDecodingContext] = context

        let root: UIComponent

        do {
            root = try decoder.decode(UIComponent.self, from: data)
        } catch let error as JUNParseError {
            report(context.diagnostics)
            throw error
        } catch is JUNComponentUnrenderable {
            report(context.diagnostics)
            throw JUNParseError.unrenderableRoot(diagnostics: context.diagnostics)
        } catch {
            report(context.diagnostics)
            throw JSONLoaderError.decodingFailed(error)
        }

        // An unknown root is not something the `.skip` policy can degrade around: skipping it
        // would leave nothing to render.
        if case .unknown(let typeString) = root.type, options.unknownComponents == .skip {
            report(context.diagnostics)
            throw JUNParseError.unsupportedComponent(type: typeString, path: "<root>")
        }

        report(context.diagnostics)

        return JUNDocument(root: root, diagnostics: context.diagnostics)
    }

    /// Surfaces diagnostics in debug builds without the caller having to opt in.
    ///
    /// Release builds stay silent — diagnostics travel on ``JUNDocument`` so the host can send
    /// them wherever it sends its telemetry.
    private static func report(_ diagnostics: [JUNDiagnostic]) {
        #if DEBUG
        guard !diagnostics.isEmpty else { return }

        let logger: Logger = Logger(subsystem: "com.jun.swiftui", category: "parsing")

        for diagnostic in diagnostics {
            switch diagnostic.severity {
            case .error:
                logger.error("JUN \(diagnostic.description, privacy: .public)")
            case .warning:
                logger.warning("JUN \(diagnostic.description, privacy: .public)")
            }
        }
        #endif
    }
}

/// Errors raised while obtaining or reading a document, as distinct from ``JUNParseError``,
/// which covers the content of a document that was read successfully.
public enum JSONLoaderError: LocalizedError {
    case fileNotFound(String)
    case invalidString
    case notAFileURL(URL)
    case httpError(statusCode: Int, url: URL)
    case decodingFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "JSON file '\(filename)' not found in bundle"

        case .invalidString:
            return "Invalid JSON string - could not convert to data"

        case .notAFileURL(let url):
            return "\(url.scheme ?? "This") URLs must be loaded with load(from:session:options:), which does not block the caller"

        case .httpError(let statusCode, let url):
            return "Request for \(url.absoluteString) failed with HTTP \(statusCode)"

        case .decodingFailed(let error):
            return "Failed to decode JSON: \(error.localizedDescription)"
        }
    }
}
