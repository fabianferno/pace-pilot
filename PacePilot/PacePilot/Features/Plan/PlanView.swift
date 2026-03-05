import SwiftUI

struct PlanView: View {
    @StateObject private var vm = PlanViewModel()
    @State private var selectedDate = Date()
    @State private var showReplanSheet = false

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .accentColor(.accentColor)
                    .padding(.horizontal)
                emptyPlanBanner
                workoutsForSelectedDate
            }
            .navigationTitle("Training Plan")
            .task { await vm.load() }
            .sheet(isPresented: $showReplanSheet) {
                ReplanSheet()
            }
        }
    }

    @ViewBuilder
    var emptyPlanBanner: some View {
        if !vm.isLoading && vm.plan == nil {
            VStack(spacing: 12) {
                Image(systemName: "figure.run.circle")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("No training plan yet")
                    .font(.headline)
                Text("Talk to your coach to create a personalised plan.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button(action: { showReplanSheet = true }) {
                    Label("Create Training Plan", systemImage: "mic.fill")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                }
            }
            .padding(32)
        }
    }

    var workoutsForSelectedDate: some View {
        let dayWorkouts = vm.workouts.filter {
            Calendar.current.isDate($0.scheduledDate, inSameDayAs: selectedDate)
        }
        return List(dayWorkouts) { workout in
            VStack(alignment: .leading, spacing: 6) {
                Text(workout.type.rawValue.capitalized).font(.headline)
                Text(String(format: "%.1f km · %@", workout.targetDistanceKm, workout.targetPaceZone))
                    .font(.caption).foregroundColor(.secondary)
            }
            .swipeActions {
                Button("Skip", role: .destructive) { Task { await vm.skipWorkout(workout.id) } }
            }
        }
        .listStyle(.insetGrouped)
    }
}
