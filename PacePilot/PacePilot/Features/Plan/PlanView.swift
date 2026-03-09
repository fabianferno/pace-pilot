import SwiftUI

struct PlanView: View {
    @StateObject private var vm = PlanViewModel()
    @State private var selectedDate = Date()
    @State private var showReplanSheet = false
    @State private var displayedMonth = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                calendarSection
                if vm.isLoading {
                    Spacer()
                    ProgressView("Loading your plan...")
                        .padding()
                    Spacer()
                } else {
                    emptyPlanBanner
                    workoutsForSelectedDate
                    completedRunBanner
                    Spacer()
                }
            }
            .navigationTitle("Training Plan")
            .task { await vm.load() }
            .sheet(isPresented: $showReplanSheet) {
                ReplanSheet()
            }
        }
    }

    // MARK: - Calendar

    var calendarSection: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button { changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                Spacer()
                Button { changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            // Day-of-week headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            // Day cells
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        dayCell(for: date)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let hasWorkout = vm.hasWorkout(on: date)
        let hasRun = vm.hasCompletedRun(on: date)

        return Button { selectedDate = date } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(isSelected ? .black : isToday ? .accentColor : .primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.accentColor : Color.clear)
                    )

                // Dot markers
                HStack(spacing: 3) {
                    if hasRun {
                        Image(systemName: "shoe.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.accentColor)
                            .rotationEffect(.degrees(25))
                    } else if hasWorkout {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 7)
            }
        }
        .buttonStyle(.plain)
        .frame(height: 42)
    }

    func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    func daysInMonth() -> [Date?] {
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let weekdayOfFirst = calendar.component(.weekday, from: firstDay) - 1 // 0-indexed Sunday

        var days: [Date?] = Array(repeating: nil, count: weekdayOfFirst)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    // MARK: - Other sections

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

    @ViewBuilder
    var workoutsForSelectedDate: some View {
        let dayWorkouts = vm.workouts.filter {
            Calendar.current.isDate($0.scheduledDate, inSameDayAs: selectedDate)
        }
        if !dayWorkouts.isEmpty {
            VStack(spacing: 8) {
                ForEach(dayWorkouts) { workout in
                    HStack(spacing: 12) {
                        Image(systemName: "figure.run")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workout.type.rawValue.capitalized)
                                .font(.subheadline.bold())
                            Text(String(format: "%.1f km · %@", workout.targetDistanceKm, workout.targetPaceZone))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Skip", role: .confirm) {
                            Task { await vm.skipWorkout(workout.id) }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
    }

    @ViewBuilder
    var completedRunBanner: some View {
        let dayRuns = vm.runs(on: selectedDate)
        if !dayRuns.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("You ran on this day!")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .padding(.top, 4)

                ForEach(dayRuns) { run in
                    NavigationLink(destination: RunHistoryDetailView(run: run)) {
                        HStack(spacing: 12) {
                            Image(systemName: "shoe.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(format: "%.2f km", run.distanceKm))
                                    .font(.subheadline.bold())
                                HStack(spacing: 12) {
                                    Label(RunTimeFormatter.format(seconds: run.durationSeconds), systemImage: "clock")
                                    Label(PaceFormatter.format(secondsPerKm: run.avgPaceSecondsPerKm) + "/km", systemImage: "speedometer")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}

#if DEBUG
#Preview("Training Plan") {
    PlanView()
        .preferredColorScheme(.dark)
}
#endif
