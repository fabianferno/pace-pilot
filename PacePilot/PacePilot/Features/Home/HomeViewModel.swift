import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var todaysWorkout: Workout?
    @Published var weeklyDistanceKm: Double = 0
    @Published var weeklyRuns: Int = 0
    @Published var isLoading = false
    @Published var error: String?

    private let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
    }

    var greetingLine: String {
        let name = AuthManager.shared.currentUser?.displayName
            .components(separatedBy: " ").first ?? ""
        let hour = Calendar.current.component(.hour, from: Date())
        let salutation: String
        switch hour {
        case 0..<12: salutation = "Good morning"
        case 12..<17: salutation = "Good afternoon"
        default:     salutation = "Good evening"
        }
        return name.isEmpty ? salutation : "\(salutation), \(name)"
    }

    var motivationLine: String {
        let lines = [
            "Every kilometre counts. Let's get moving.",
            "Consistency beats perfection. Lace up.",
            "Your best run is always the next one.",
            "Champions train when no one's watching.",
            "One step at a time. You've got this.",
            "The only bad run is the one you didn't do.",
            "Strong body, stronger mind. Let's go.",
        ]
        let day = Calendar.current.component(.day, from: Date())
        return lines[day % lines.count]
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            todaysWorkout = try await api.get("/api/workouts/today")
        } catch {
            self.error = error.localizedDescription
        }
        do {
            struct Stats: Decodable { let weeklyDistanceKm: Double; let weeklyRuns: Int }
            let stats: Stats = try await api.get("/api/users/me/stats")
            weeklyDistanceKm = stats.weeklyDistanceKm
            weeklyRuns = stats.weeklyRuns
        } catch {}
    }
}
