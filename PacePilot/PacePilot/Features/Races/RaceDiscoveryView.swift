import SwiftUI

struct RunDiscoveryView: View {
    @StateObject private var vm = RunsViewModel()
    @State private var showCreate = false
    @State private var filterByCity = false
    @State private var userCity: String = ""

    private var displayedRuns: [CommunityRun] {
        guard filterByCity, !userCity.isEmpty else { return vm.runs }
        return vm.runs.filter { $0.city.lowercased() == userCity.lowercased() }
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if displayedRuns.isEmpty {
                    emptyStateView
                } else {
                    List(displayedRuns) { run in
                        NavigationLink(destination: RunDetailView(run: run, vm: vm)) {
                            RunRow(run: run)
                        }
                    }
                }
            }
            .navigationTitle("Runs")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !userCity.isEmpty {
                        Toggle(isOn: $filterByCity) {
                            Label("My City", systemImage: "location.fill")
                                .font(.caption)
                        }
                        .toggleStyle(.button)
                        .tint(.accentColor)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showCreate = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateRunView(vm: vm)
            }
            .task {
                userCity = AuthManager.shared.currentUser?.city ?? ""
                await vm.load()
            }
        }
    }

    var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "figure.run.circle")
                .font(.system(size: 60))
                .foregroundColor(.accentColor.opacity(0.8))
            VStack(spacing: 8) {
                Text(filterByCity ? "No Runs in \(userCity)" : "No Runs Yet")
                    .font(.title2.bold())
                Text(filterByCity
                     ? "No upcoming runs in your city. Try showing all runs."
                     : "Be the first to host a community run!")
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

private struct RunRow: View {
    let run: CommunityRun

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(run.name).font(.headline)
                Spacer()
                if run.isRsvpdByUser {
                    Label("Going", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(.accentColor)
                }
            }
            HStack(spacing: 12) {
                Label(String(format: "%.0f km", run.distanceKm), systemImage: "ruler")
                Label(run.city, systemImage: "mappin")
                Label(run.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
            }
            .font(.caption).foregroundColor(.secondary)
            if run.rsvpCount > 0 {
                Text("\(run.rsvpCount) going")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
