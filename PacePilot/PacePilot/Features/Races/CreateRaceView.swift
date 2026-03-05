import SwiftUI

struct CreateRaceView: View {
    @ObservedObject var vm: RacesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var distanceKmText = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var registrationURL = ""
    @State private var elevationText = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(distanceKmText) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Race Details") {
                    TextField("Name", text: $name)
                    TextField("Distance (km)", text: $distanceKmText)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date, in: Date()..., displayedComponents: .date)
                    TextField("Location", text: $location)
                }
                Section("Optional") {
                    TextField("Registration URL", text: $registrationURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Elevation Gain (m)", text: $elevationText)
                        .keyboardType(.decimalPad)
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Race")
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
        }
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        guard let distanceKm = Double(distanceKmText) else { return }
        do {
            try await vm.createRace(
                name: name.trimmingCharacters(in: .whitespaces),
                distanceKm: distanceKm,
                date: date,
                location: location.trimmingCharacters(in: .whitespaces),
                registrationUrl: registrationURL.isEmpty ? nil : registrationURL,
                elevationGainMeters: elevationText.isEmpty ? nil : Double(elevationText)
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
