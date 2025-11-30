//
//  ContentView.swift
//  JSONToSwiftUIApp
//
//  Created by Pawel Zgoda-Ferchmin on 28/11/2025.
//

import SwiftUI
import JSONToSwiftUI

extension UIComponent: Hashable {
    public static func == (lhs: UIComponent, rhs: UIComponent) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ContentView: View {
    @State private var errorMessage: String?
    @State private var showingJSONInput: Bool = false
    @State private var jsonInputText: String = ""
    @State private var navigationPath = NavigationPath()

    private let availableSamples: [String] = [
        "simple-layout",
        "complex-layout",
        "horizontal-scroll"
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            sampleSelectorView
                .navigationTitle("JSON → SwiftUI")
                .navigationDestination(for: UIComponent.self) { component in
                    ComponentDetailView(component: component)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingJSONInput = true
                        } label: {
                            Label("Paste JSON", systemImage: "doc.text")
                        }
                    }
                }
                .sheet(isPresented: $showingJSONInput) {
                    jsonInputSheet
                }
        }
    }

    // MARK: - Sample Selector View

    @ViewBuilder
    private var sampleSelectorView: some View {
        VStack(spacing: 20) {
            Text("Select a Sample")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 40)

            Text("Choose a JSON sample to render as SwiftUI")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            List {
                ForEach(availableSamples, id: \.self) { sample in
                    Button {
                        if let component = loadSampleComponent(sample) {
                            navigationPath.append(component)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatSampleName(sample))
                                    .font(.headline)

                                Text(getSampleDescription(sample))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }


    // MARK: - JSON Input Sheet

    @ViewBuilder
    private var jsonInputSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Paste your JSON here")
                    .font(.headline)
                    .padding(.top)

                TextEditor(text: $jsonInputText)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)

                Button {
                    if let component = loadFromString(jsonInputText) {
                        navigationPath.append(component)
                    }
                    showingJSONInput = false
                    jsonInputText = ""
                } label: {
                    Text("Render")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(jsonInputText.isEmpty)

                Spacer()
            }
            .navigationTitle("Custom JSON")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingJSONInput = false
                        jsonInputText = ""
                    }
                }
            }
        }
    }

    // MARK: - Loading Functions

    private func loadSampleComponent(_ sampleName: String) -> UIComponent? {
        errorMessage = nil

        guard let url = Bundle.main.url(forResource: sampleName, withExtension: "json") else {
            errorMessage = "Could not find sample '\(sampleName)' in app bundle"
            return nil
        }

        do {
            return try JSONLoader.loadFromURL(url)
        } catch {
            errorMessage = "Failed to load sample: \(error.localizedDescription)"
            return nil
        }
    }

    private func loadFromString(_ jsonString: String) -> UIComponent? {
        errorMessage = nil

        do {
            return try JSONLoader.loadFromString(jsonString)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Helpers

    private func formatSampleName(_ name: String) -> String {
        return name
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    private func getSampleDescription(_ name: String) -> String {
        switch name {
        case "simple-layout":
            return "Basic VStack, HStack, Text, Image, Button"
        case "complex-layout":
            return "Product list with nested layouts and ScrollView"
        case "horizontal-scroll":
            return "Horizontal ScrollView with ZStack and shapes"
        default:
            return "JSON-to-SwiftUI example"
        }
    }
}

// MARK: - Component Detail View

struct ComponentDetailView: View {
    let component: UIComponent

    var body: some View {
        ComponentRenderer(component: component)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Rendered View")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
