import SwiftUI

/// Main view for the JSON-to-SwiftUI POC app
public struct ContentView: View {
    @State private var viewModel: JSONToSwiftUIViewModel = JSONToSwiftUIViewModel()
    @State private var showingJSONInput: Bool = false
    @State private var jsonInputText: String = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Sample Selector
                if viewModel.component == nil {
                    sampleSelectorView
                } else {
                    // Rendered Component
                    renderedComponentView
                }
            }
            .navigationTitle("JSON → SwiftUI")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingJSONInput = true
                        } label: {
                            Label("Paste JSON", systemImage: "doc.text")
                        }

                        Button {
                            viewModel.clear()
                        } label: {
                            Label("Clear", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingJSONInput = true
                        } label: {
                            Label("Paste JSON", systemImage: "doc.text")
                        }

                        Button {
                            viewModel.clear()
                        } label: {
                            Label("Clear", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingJSONInput) {
                jsonInputSheet
            }
        }
        .onAppear {
            // Load first sample by default
            if !viewModel.availableSamples.isEmpty {
                viewModel.loadSample(viewModel.availableSamples[0])
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
                ForEach(viewModel.availableSamples, id: \.self) { sample in
                    Button {
                        viewModel.loadSample(sample)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatSampleName(sample))
                                    .font(.headline)
                                    .foregroundColor(.primary)

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
                    }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.bordered)
            #endif

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }

    // MARK: - Rendered Component View

    @ViewBuilder
    private var renderedComponentView: some View {
        VStack(spacing: 0) {
            // Header with info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rendered from JSON")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let component = viewModel.component {
                        Text("Root: \(component.type.typeString)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                Button {
                    viewModel.clear()
                } label: {
                    Text("Back")
                        .font(.subheadline)
                }
            }
            .padding()
            #if os(iOS)
            .background(Color(uiColor: .systemGroupedBackground))
            #else
            .background(Color(nsColor: .windowBackgroundColor))
            #endif

            Divider()

            // Rendered component
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)

                    Text("Error")
                        .font(.headline)

                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let component = viewModel.component {
                ScrollView {
                    ComponentRenderer(component: component)
                        .frame(maxWidth: .infinity)
                }
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
                    #if os(iOS)
                    .background(Color(uiColor: .systemGray6))
                    #else
                    .background(Color(nsColor: .textBackgroundColor))
                    #endif
                    .cornerRadius(8)
                    .padding(.horizontal)

                Button {
                    viewModel.loadFromString(jsonInputText)
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingJSONInput = false
                        jsonInputText = ""
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingJSONInput = false
                        jsonInputText = ""
                    }
                }
                #endif
            }
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

#Preview {
    ContentView()
}
