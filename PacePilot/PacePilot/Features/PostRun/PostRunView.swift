import SwiftUI
import MapKit

struct PostRunView: View {
    let runRequest: NewRunRequest
    @StateObject private var vm = PostRunViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if vm.agentSpeaking {
                        debriefBanner
                    }
                    summaryCard
                    if !runRequest.gpsTrack.isEmpty {
                        mapCard
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Run Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { Task { await vm.finish(); dismiss() } }
                }
            }
            .task { await vm.saveAndDebrief(run: runRequest) }
        }
    }

    var debriefBanner: some View {
        HStack {
            Image(systemName: "waveform").foregroundColor(.accentColor)
            Text("Coach debrief in progress...")
                .font(.subheadline)
                .foregroundColor(.accentColor)
            Spacer()
        }
        .padding()
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(12)
    }

    var summaryCard: some View {
        VStack(spacing: 16) {
            Text("Summary").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                statCell(value: String(format: "%.2f km", runRequest.distanceKm), label: "Distance")
                statCell(value: RunTimeFormatter.format(seconds: runRequest.durationSeconds), label: "Duration")
                statCell(value: PaceFormatter.format(secondsPerKm: runRequest.avgPaceSecondsPerKm) + "/km", label: "Avg Pace")
                statCell(value: "\(runRequest.avgHeartRate) bpm", label: "Avg HR")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }

    var mapCard: some View {
        let coords = runRequest.gpsTrack.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        let region = MKCoordinateRegion(
            center: coords.first ?? CLLocationCoordinate2D(),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        return Map(initialPosition: .region(region)) {
            MapPolyline(coordinates: coords)
                .stroke(Color.accentColor, lineWidth: 3)
        }
        .frame(height: 200)
        .cornerRadius(16)
    }
}
