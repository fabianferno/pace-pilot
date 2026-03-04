import SwiftUI

struct RunHistoryView: View {
    @StateObject private var vm = HistoryViewModel()

    var body: some View {
        NavigationStack {
            List(vm.runs) { run in
                NavigationLink(destination: RunDetailView(run: run)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(run.startedAt.formatted(date: .abbreviated, time: .shortened)).font(.headline)
                        HStack(spacing: 16) {
                            Label(String(format: "%.2f km", run.distanceKm), systemImage: "ruler")
                            Label(RunTimeFormatter.format(seconds: run.durationSeconds), systemImage: "clock")
                            Label(PaceFormatter.format(secondsPerKm: run.avgPaceSecondsPerKm) + "/km", systemImage: "speedometer")
                        }
                        .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("History")
            .task { await vm.load() }
        }
    }
}

struct RunDetailView: View {
    let run: RunSession

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryGrid
                splitsSection
            }
            .padding()
        }
        .navigationTitle(run.startedAt.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }

    var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statCell(value: String(format: "%.2f km", run.distanceKm), label: "Distance")
            statCell(value: RunTimeFormatter.format(seconds: run.durationSeconds), label: "Duration")
            statCell(value: PaceFormatter.format(secondsPerKm: run.avgPaceSecondsPerKm) + "/km", label: "Avg Pace")
            statCell(value: "\(run.avgHeartRate) bpm", label: "Avg HR")
            statCell(value: "\(run.calories) kcal", label: "Calories")
            statCell(value: String(format: "%.0f m", run.elevationGainMeters), label: "Elevation")
        }
    }

    func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    var splitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Splits").font(.headline)
            ForEach(run.splits, id: \.kmNumber) { split in
                HStack {
                    Text("KM \(split.kmNumber)").font(.subheadline)
                    Spacer()
                    Text(PaceFormatter.format(secondsPerKm: split.paceSecondsPerKm) + "/km")
                    Text("\(split.avgHeartRate) bpm").foregroundColor(.secondary)
                }
                .font(.caption)
                Divider()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}
