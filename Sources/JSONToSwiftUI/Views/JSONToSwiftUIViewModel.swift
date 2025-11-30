import Foundation
import SwiftUI

/// ViewModel for managing JSON-to-SwiftUI rendering
@MainActor
@Observable
class JSONToSwiftUIViewModel {
    var component: UIComponent?
    var errorMessage: String?
    var isLoading: Bool = false
    var availableSamples: [String] = [
        "simple-layout",
        "complex-layout",
        "horizontal-scroll"
    ]

    /// Load a component from a JSON string
    func loadFromString(_ jsonString: String) {
        isLoading = true
        errorMessage = nil

        do {
            component = try JSONLoader.loadFromString(jsonString)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Load a component from a file URL
    func loadFromURL(_ url: URL) {
        isLoading = true
        errorMessage = nil

        do {
            component = try JSONLoader.loadFromURL(url)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Load a sample component
    func loadSample(_ sampleName: String) {
        isLoading = true
        errorMessage = nil

        // Try to load from Resources/SampleJSON directory
        let resourcePath: String = "/Users/pawel/JSONToSwiftUIPOC/Resources/SampleJSON/\(sampleName).json"
        let url: URL = URL(fileURLWithPath: resourcePath)

        do {
            component = try JSONLoader.loadFromURL(url)
        } catch {
            errorMessage = "Failed to load sample '\(sampleName)': \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Clear the current component
    func clear() {
        component = nil
        errorMessage = nil
    }
}
