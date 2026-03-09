import SwiftUI
import MapKit

struct RunDetailView: View {
    let run: CommunityRun
    @ObservedObject var vm: RunsViewModel
    @Environment(\.dismiss) private var dismiss

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: run.latitude, longitude: run.longitude)
    }

    private var currentRun: CommunityRun {
        vm.runs.first(where: { $0.id == run.id }) ?? run
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Map(position: .constant(.region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )))) {
                    Marker(run.name, coordinate: coordinate)
                }
                .frame(height: 220)
                .disabled(true)

                VStack(alignment: .leading, spacing: 16) {
                    Text(run.name)
                        .font(.title2.bold())

                    HStack(spacing: 20) {
                        Label(String(format: "%.0f km", run.distanceKm), systemImage: "ruler")
                        Label(run.city, systemImage: "mappin")
                        Label(run.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    Label(run.location, systemImage: "location")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.secondary)
                        Text("\(currentRun.rsvpCount) going")
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)

                    Divider()

                    Button(action: {
                        Task {
                            if currentRun.isRsvpdByUser {
                                await vm.unrsvp(run.id)
                            } else {
                                await vm.rsvp(run.id)
                            }
                        }
                    }) {
                        Label(
                            currentRun.isRsvpdByUser ? "Can't Go" : "Going",
                            systemImage: currentRun.isRsvpdByUser ? "xmark.circle" : "checkmark.circle.fill"
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(currentRun.isRsvpdByUser ? Color(.systemGray5) : Color.accentColor)
                        .foregroundColor(currentRun.isRsvpdByUser ? .primary : .black)
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
        }
        .navigationTitle("Run Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview("Run Detail") {
    NavigationStack {
        RunDetailView(run: PreviewData.communityRuns[0], vm: RunsViewModel())
    }
    .preferredColorScheme(.dark)
}
#endif
