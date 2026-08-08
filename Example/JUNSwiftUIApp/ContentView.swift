//
//  ContentView.swift
//  JUNSwiftUIApp
//
//  Created by Pawel Zgoda-Ferchmin on 28/11/2025.
//

import SwiftUI
import JUNSwiftUI

struct ContentView: View {
    @State private var errorMessage: String?
    @State private var showingJSONInput: Bool = false
    @State private var jsonInputText: String = ""
    @State private var navigationPath: NavigationPath = NavigationPath()

    /// Synced from the JUN repository by `Scripts/sync-examples.sh`.
    private let availableSamples: [String] = [
        "simple-layout",
        "product-list",
        "horizontal-scroll",
        "remote-images",
        "font-showcase",
        "counter"
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                sampleSelectorView
            }
            .navigationTitle("JUN → SwiftUI")
            .navigationDestination(for: JUNDocument.self) { document in
                DocumentDetailView(document: document)
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
        Section {
            ForEach(availableSamples, id: \.self) { sample in
                Button {
                    if let document = loadSample(sample) {
                        navigationPath.append(document)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatSampleName(sample))
                                .font(.headline)

                            Text(description(of: sample))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } header: {
            VStack(alignment: .leading, spacing: 6) {
                Text("Canonical JUN Examples")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("The specification's own documents, rendered by JUNSwiftUI")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .textCase(nil)
            .padding(.vertical, 8)
        }

        if let errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    // MARK: - JSON Input Sheet

    @ViewBuilder
    private var jsonInputSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Paste a JUN document")
                    .font(.headline)
                    .padding(.top)

                TextEditor(text: $jsonInputText)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color(uiColor: .systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(.horizontal)

                Button {
                    if let document = loadFromString(jsonInputText) {
                        navigationPath.append(document)
                        showingJSONInput = false
                        jsonInputText = ""
                    }
                } label: {
                    Text("Render")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .padding(.horizontal)
                .disabled(jsonInputText.isEmpty)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Custom JSON")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingJSONInput = false
                        jsonInputText = ""
                        errorMessage = nil
                    }
                }
            }
        }
    }

    // MARK: - Loading

    private func loadSample(_ name: String) -> JUNDocument? {
        errorMessage = nil

        do {
            return try JSONLoader.loadFromBundle(filename: name)
        } catch {
            errorMessage = "Failed to load '\(name)': \(error.localizedDescription)"
            return nil
        }
    }

    private func loadFromString(_ jsonString: String) -> JUNDocument? {
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
        name.replacingOccurrences(of: "-", with: " ").capitalized
    }

    private func description(of name: String) -> String {
        switch name {
        case "simple-layout":
            return "VStack, HStack, Text, shapes and a button"
        case "product-list":
            return "Scrollable catalog with nested cards"
        case "horizontal-scroll":
            return "Horizontal gallery with remote images"
        case "remote-images":
            return "AsyncImage sizing, clipping and loading states"
        case "font-showcase":
            return "The font property across several typefaces"
        case "counter":
            return "Actions with parameters, handled by this app"
        default:
            return "JUN document"
        }
    }
}

// MARK: - Document Detail View

struct DocumentDetailView: View {
    let document: JUNDocument

    @State private var count: Int = 0
    @State private var lastAction: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if !document.diagnostics.isEmpty {
                    diagnosticsBanner
                }

                ComponentRenderer(document: document)
                    .frame(maxWidth: .infinity)
                    .junActionHandler(handle)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let lastAction {
                actionBanner(lastAction)
            }
        }
        .navigationTitle("Rendered")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Interprets the actions the counter example names. A document can only name an intent —
    /// this is where the app decides what it means.
    private func handle(_ action: JUNAction) {
        switch action.name {
        case "adjustCount":
            count += action.params["by"]?.intValue ?? 0
        case "resetCount":
            count = 0
        default:
            break
        }

        lastAction = "\(action.name)\(action.params.isEmpty ? "" : " \(action.params)") → count \(count)"
    }

    @ViewBuilder
    private var diagnosticsBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(
                "\(document.diagnostics.count) diagnostic\(document.diagnostics.count == 1 ? "" : "s")",
                systemImage: document.hasErrors ? "exclamationmark.triangle.fill" : "info.circle"
            )
            .font(.caption.weight(.semibold))

            ForEach(Array(document.diagnostics.enumerated()), id: \.offset) { _, diagnostic in
                Text(diagnostic.description)
                    .font(.caption2.monospaced())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(document.hasErrors ? Color.red.opacity(0.12) : Color.yellow.opacity(0.15))
    }

    @ViewBuilder
    private func actionBanner(_ text: String) -> some View {
        Text(text)
            .font(.caption.monospaced())
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
    }
}

#Preview {
    ContentView()
}
