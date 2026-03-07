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
            ScrollView {
                VStack(spacing: 0) {
                    runsHeaderCard
                        .padding(.horizontal)
                        .padding(.top)

                    if vm.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if displayedRuns.isEmpty {
                        emptyStateView
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(displayedRuns) { run in
                                NavigationLink(destination: RunDetailView(run: run, vm: vm)) {
                                    RunRow(run: run)
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                                Divider()
                                    .padding(.horizontal)
                            }
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

    var runsHeaderCard: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.18, green: 0.18, blue: 0.28)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            Image("RunnerMale")
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .padding(.bottom, -4)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Discover Runs")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("Find your next group run.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
