import SwiftUI

struct PlanView: View {
    @StateObject private var vm = PlanViewModel()
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .accentColor(.accentColor)
                    .padding(.horizontal)
                workoutsForSelectedDate
            }
            .navigationTitle("Training Plan")
            .task { await vm.load() }
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
