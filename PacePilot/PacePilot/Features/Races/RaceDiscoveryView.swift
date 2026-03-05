import SwiftUI

struct RaceDiscoveryView: View {
    @StateObject private var vm = RacesViewModel()
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.races.isEmpty {
                    emptyStateView
                } else {
                    List(vm.races) { race in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(race.name).font(.headline)
                                Spacer()
                                if race.isInterestedByUser {
                                    Image(systemName: "star.fill").foregroundColor(.accentColor)
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
                                    .tint(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Races")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showCreate = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateRaceView(vm: vm)
            }
            .task { await vm.load() }
        }
    }

    var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "flag.checkered")
                .font(.system(size: 60))
                .foregroundColor(.accentColor.opacity(0.8))
            VStack(spacing: 8) {
                Text("No Races Yet")
                    .font(.title2.bold())
                Text("Upcoming races will appear here once they're added. Check back soon to discover events near you.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
