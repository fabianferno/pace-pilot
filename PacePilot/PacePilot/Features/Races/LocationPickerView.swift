import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    var onSelect: (CLLocationCoordinate2D, String, String) -> Void
    // onSelect(coordinate, displayLocation, city)

    @State private var query = ""
    @State private var results: [MKMapItem] = []
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocation = ""
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search for a place", text: $query)
                        .onSubmit { Task { await search() } }
                    if isSearching {
                        ProgressView().scaleEffect(0.7)
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                if results.isEmpty && selectedCoordinate == nil {
                    Spacer()
                } else if !results.isEmpty && selectedCoordinate == nil {
                    List(results, id: \.self) { item in
                        Button(action: { select(item) }) {
                            VStack(alignment: .leading) {
                                Text(item.name ?? "Unknown").font(.body)
                                if let addr = item.placemark.title {
                                    Text(addr).font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } else if let coord = selectedCoordinate {
                    Map(position: $cameraPosition) {
                        Marker(selectedLocation, coordinate: coord)
                    }
                    .frame(maxHeight: .infinity)

                    Button("Confirm Location") {
                        Task { await confirmLocation(coord) }
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }

                Spacer()
            }
            .navigationTitle("Pick Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if selectedCoordinate != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") {
                            selectedCoordinate = nil
                            results = []
                        }
                    }
                }
            }
        }
    }

    private func search() async {
        guard !query.isEmpty else { return }
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        results = (try? await search.start())?.mapItems ?? []
        isSearching = false
    }

    private func select(_ item: MKMapItem) {
        let coord = item.placemark.coordinate
        selectedCoordinate = coord
        selectedLocation = item.name ?? query
        cameraPosition = .region(MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
        results = []
    }

    private func confirmLocation(_ coord: CLLocationCoordinate2D) async {
        let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let placemarks = try? await CLGeocoder().reverseGeocodeLocation(loc)
        let city = placemarks?.first?.locality ?? placemarks?.first?.administrativeArea ?? "Unknown"
        dismiss()
        onSelect(coord, selectedLocation, city)
    }
}

#if DEBUG
#Preview("Location Picker") {
    LocationPickerView { _, _, _ in }
        .preferredColorScheme(.dark)
}
#endif
