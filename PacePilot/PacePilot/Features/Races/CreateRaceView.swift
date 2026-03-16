import SwiftUI
import MapKit

struct CreateRunView: View {
    @ObservedObject var vm: RunsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var distanceKmText = ""
    @State private var date = Date()
    @State private var locationDisplay = ""
    @State private var city = ""
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var showLocationPicker = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(distanceKmText) != nil &&
        latitude != nil &&
        longitude != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Run Details") {
                    TextField("Name", text: $name)
                    TextField("Distance (km)", text: $distanceKmText)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date, in: Date()..., displayedComponents: .date)
                }
                Section("Location") {
                    Button(action: { showLocationPicker = true }) {
                        HStack {
                            Label(
                                locationDisplay.isEmpty ? "Pick on Map" : locationDisplay,
                                systemImage: "mappin.and.ellipse"
                            )
                            .foregroundColor(locationDisplay.isEmpty ? .brand : .primary)
                            Spacer()
                            if !locationDisplay.isEmpty {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    if !city.isEmpty {
                        LabeledContent("City", value: city)
                            .foregroundColor(.secondary)
                    }
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("New Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { Task { await submit() } }
                        .disabled(!isValid || isSubmitting)
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView { coord, display, resolvedCity in
                    latitude = coord.latitude
                    longitude = coord.longitude
                    locationDisplay = display
                    city = resolvedCity
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        guard let distanceKm = Double(distanceKmText),
              let lat = latitude, let lng = longitude else { return }
        do {
            try await vm.createRun(
                name: name.trimmingCharacters(in: .whitespaces),
                distanceKm: distanceKm,
                date: date,
                location: locationDisplay,
                city: city,
                latitude: lat,
                longitude: lng
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#if DEBUG
#Preview("Create Run") {
    CreateRunView(vm: RunsViewModel())
        .preferredColorScheme(.dark)
}
#endif
