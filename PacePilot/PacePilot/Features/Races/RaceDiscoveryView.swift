import SwiftUI

struct RaceDiscoveryView: View {
    @StateObject private var vm = RacesViewModel()

    var body: some View {
        NavigationStack {
            List(vm.races) { race in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(race.name).font(.headline)
                        Spacer()
                        if race.isInterestedByUser {
                            Image(systemName: "star.fill").foregroundColor(.orange)
                        }
                    }
                    HStack(spacing: 12) {
                        Label(String(format: "%.0f km", race.distanceKm), systemImage: "ruler")
                        Label(race.location, systemImage: "mappin")
                        Label(race.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    }
                    .font(.caption).foregroundColor(.secondary)
                }
                .swipeActions {
                    if !race.isInterestedByUser {
                        Button("Interested") { Task { await vm.markInterest(race.id) } }
                            .tint(.orange)
                    }
                }
            }
            .navigationTitle("Races")
            .task { await vm.load() }
        }
    }
}
