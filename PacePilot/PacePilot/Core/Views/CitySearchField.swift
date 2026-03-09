import SwiftUI
import MapKit
import Combine

/// A text field with autocomplete suggestions powered by MKLocalSearchCompleter,
/// restricted to city-level results. Ensures the saved city name matches Apple's
/// canonical geocoding names (same source used by LocationPickerView).
struct CitySearchField: View {
    @Binding var city: String
    @StateObject private var completer = CityCompleter()
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("City")
                Spacer()
                TextField("Search city", text: $completer.query)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.secondary)
                    .focused($isFocused)
                    .onChange(of: completer.query) { _, newValue in
                        // If the user clears the field, clear the binding too
                        if newValue.isEmpty { city = "" }
                    }
                if !city.isEmpty && isFocused {
                    Button {
                        completer.query = ""
                        city = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if isFocused && !completer.suggestions.isEmpty && city != completer.query {
                Divider().padding(.top, 8)
                ForEach(completer.suggestions, id: \.self) { completion in
                    Button {
                        let selected = completion.title
                        city = selected
                        completer.query = selected
                        completer.suggestions = []
                        isFocused = false
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(completion.title)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onChange(of: city) { _, newValue in
            // Sync binding → completer when the value arrives from the profile load
            if completer.query != newValue {
                completer.query = newValue
            }
        }
        .onAppear {
            completer.query = city
        }
    }
}

// MARK: - MKLocalSearchCompleter wrapper

@MainActor
private final class CityCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query = "" {
        didSet { completer.queryFragment = query }
    }
    @Published var suggestions: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        completer.resultTypes = .address
        super.init()
        completer.delegate = self
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results.filter { completion in
            // Keep only city/region level results (no specific addresses)
            completion.subtitle.isEmpty || !completion.title.contains(",")
                || completion.subtitle.contains(completion.title) == false
        }
        Task { @MainActor in
            self.suggestions = Array(results.prefix(5))
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Silently ignore — user can still type and retry
    }
}
