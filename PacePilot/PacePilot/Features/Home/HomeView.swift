import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var showActiveRun = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    greetingCard
                    weeklyStatsCard
                    if let workout = vm.todaysWorkout {
                        todaysWorkoutCard(workout)
                    } else if !vm.isLoading {
                        restDayCard
                    }
                    startRunButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        Text("PacePilot")
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                    }
                }
            }
            .task { await vm.load() }
            .fullScreenCover(isPresented: $showActiveRun) {
                ActiveRunView()
            }
        }
    }

    var greetingCard: some View {
        ZStack(alignment: .bottomLeading) {
            GIFImageView(name: "artistic-runner")
                .frame(maxWidth: .infinity)
                .frame(height: 180)

            LinearGradient(
                colors: [.black.opacity(0.6), .black.opacity(0.1), .clear],
                startPoint: .bottom,
                endPoint: .top
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(vm.greetingLine)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text(vm.motivationLine)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding()
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    var weeklyStatsCard: some View {
        HStack(spacing: 0) {
            statItem(value: String(format: "%.1f", vm.weeklyDistanceKm), label: "km this week")
            Divider().frame(height: 40)
            statItem(value: "\(vm.weeklyRuns)", label: "runs")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    func statItem(value: String, label: String) -> some View {
        VStack {
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    func todaysWorkoutCard(_ workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Today's Workout", systemImage: "calendar.badge.clock")
                .font(.headline)
            Text(workout.type.rawValue.capitalized)
                .font(.title3.bold())
            HStack {
                Label(String(format: "%.1f km", workout.targetDistanceKm), systemImage: "ruler")
                Spacer()
                Label(workout.targetPaceZone, systemImage: "speedometer")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    var restDayCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.zzz").font(.largeTitle).foregroundColor(.accentColor)
            Text("Rest Day").font(.headline)
            Text("Recovery is part of training.").font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    var startRunButton: some View {
        Button(action: { showActiveRun = true }) {
            Label("Start Run", systemImage: "figure.run")
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(16)
        }
    }
}
