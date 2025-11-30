import Foundation

/// Loads and decodes UIComponent from JSON sources
public enum JSONLoader {

    /// Load UIComponent from a JSON file in the bundle
    public static func loadFromBundle(filename: String, bundle: Bundle = .main) throws -> UIComponent {
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            throw JSONLoaderError.fileNotFound(filename)
        }

        let data: Data = try Data(contentsOf: url)
        return try decode(data)
    }

    /// Load UIComponent from a JSON string
    public static func loadFromString(_ jsonString: String) throws -> UIComponent {
        guard let data = jsonString.data(using: .utf8) else {
            throw JSONLoaderError.invalidString
        }

        return try decode(data)
    }

    /// Load UIComponent from JSON data
    public static func loadFromData(_ data: Data) throws -> UIComponent {
        return try decode(data)
    }

    /// Load UIComponent from a file URL
    public static func loadFromURL(_ url: URL) throws -> UIComponent {
        let data: Data = try Data(contentsOf: url)
        return try decode(data)
    }

    // MARK: - Private Helpers

    private static func decode(_ data: Data) throws -> UIComponent {
        let decoder: JSONDecoder = JSONDecoder()

        do {
            return try decoder.decode(UIComponent.self, from: data)
        } catch {
            throw JSONLoaderError.decodingFailed(error)
        }
    }
}

/// Errors that can occur during JSON loading
public enum JSONLoaderError: LocalizedError {
    case fileNotFound(String)
    case invalidString
    case decodingFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "JSON file '\(filename)' not found in bundle"
        case .invalidString:
            return "Invalid JSON string - could not convert to data"
        case .decodingFailed(let error):
            return "Failed to decode JSON: \(error.localizedDescription)"
        }
    }
}
