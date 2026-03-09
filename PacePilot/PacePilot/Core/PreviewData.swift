import Foundation
import CoreLocation

#if DEBUG
enum PreviewData {

    // MARK: - User

    static let user = User(
        id: "u1",
        email: "alex@example.com",
        displayName: "Alex Runner",
        communityTier: .momentum,
        onboardingComplete: true,
        stravaConnected: true,
        googleCalendarConnected: false,
        weeklyMileageGoal: 40,
        targetRaceDistance: "half_marathon",
        targetRaceDate: Date().addingTimeInterval(90 * 86400),
        restingHr: 55,
        maxHr: 190,
        preferredDays: [0, 2, 4, 6],
        city: "San Francisco"
    )

    // MARK: - Training Plan

    static let trainingPlan = TrainingPlan(
        id: "tp1",
        userId: "u1",
        startDate: Date().addingTimeInterval(-14 * 86400),
        endDate: Date().addingTimeInterval(76 * 86400),
        phase: .build,
        paceZones: TrainingPlan.PaceZones(
            easy: 360, marathon: 300, threshold: 270, interval: 240, repetition: 210
        ),
        hrZones: TrainingPlan.HRZones(
            zone1Max: 130, zone2Max: 150, zone3Max: 165, zone4Max: 178, zone5Max: 190
        ),
        isActive: true
    )

    // MARK: - Workouts

    static let easyWorkout = Workout(
        id: "w1", planId: "tp1", scheduledDate: Date(),
        type: .easy, targetDistanceKm: 8.0, targetPaceZone: "Easy",
        segments: [
            Workout.Segment(distanceKm: 8.0, paceZone: "Easy", description: "Easy steady run")
        ],
        isCompleted: false, isSkipped: false
    )

    static let tempoWorkout = Workout(
        id: "w2", planId: "tp1",
        scheduledDate: Date().addingTimeInterval(86400),
        type: .tempo, targetDistanceKm: 10.0, targetPaceZone: "Threshold",
        segments: [
            Workout.Segment(distanceKm: 2.0, paceZone: "Easy", description: "Warm-up"),
            Workout.Segment(distanceKm: 6.0, paceZone: "Threshold", description: "Tempo"),
            Workout.Segment(distanceKm: 2.0, paceZone: "Easy", description: "Cool-down")
        ],
        isCompleted: false, isSkipped: false
    )

    static let longWorkout = Workout(
        id: "w3", planId: "tp1",
        scheduledDate: Date().addingTimeInterval(3 * 86400),
        type: .long, targetDistanceKm: 18.0, targetPaceZone: "Easy",
        segments: [], isCompleted: false, isSkipped: false
    )

    // MARK: - Run Sessions

    static let runSession = RunSession(
        id: "r1", userId: "u1", workoutId: "w1",
        startedAt: Date().addingTimeInterval(-3600),
        endedAt: Date().addingTimeInterval(-600),
        distanceKm: 7.85, durationSeconds: 2820,
        avgPaceSecondsPerKm: 359, avgHeartRate: 148, maxHeartRate: 168,
        calories: 520, elevationGainMeters: 42,
        splits: [
            RunSession.Split(kmNumber: 1, paceSecondsPerKm: 370, avgHeartRate: 140),
            RunSession.Split(kmNumber: 2, paceSecondsPerKm: 365, avgHeartRate: 145),
            RunSession.Split(kmNumber: 3, paceSecondsPerKm: 358, avgHeartRate: 148),
            RunSession.Split(kmNumber: 4, paceSecondsPerKm: 355, avgHeartRate: 150),
            RunSession.Split(kmNumber: 5, paceSecondsPerKm: 350, avgHeartRate: 152),
            RunSession.Split(kmNumber: 6, paceSecondsPerKm: 348, avgHeartRate: 155),
            RunSession.Split(kmNumber: 7, paceSecondsPerKm: 345, avgHeartRate: 158)
        ],
        gpsTrack: [
            RunSession.GPSPoint(latitude: 37.7749, longitude: -122.4194, altitude: 10, timestamp: Date().addingTimeInterval(-3600)),
            RunSession.GPSPoint(latitude: 37.7760, longitude: -122.4180, altitude: 12, timestamp: Date().addingTimeInterval(-3300)),
            RunSession.GPSPoint(latitude: 37.7775, longitude: -122.4160, altitude: 15, timestamp: Date().addingTimeInterval(-3000)),
            RunSession.GPSPoint(latitude: 37.7790, longitude: -122.4140, altitude: 13, timestamp: Date().addingTimeInterval(-2700))
        ]
    )

    static let runSession2 = RunSession(
        id: "r2", userId: "u1", workoutId: nil,
        startedAt: Date().addingTimeInterval(-2 * 86400),
        endedAt: Date().addingTimeInterval(-2 * 86400 + 1800),
        distanceKm: 5.12, durationSeconds: 1800,
        avgPaceSecondsPerKm: 351, avgHeartRate: 155, maxHeartRate: 172,
        calories: 380, elevationGainMeters: 28,
        splits: [
            RunSession.Split(kmNumber: 1, paceSecondsPerKm: 360, avgHeartRate: 148),
            RunSession.Split(kmNumber: 2, paceSecondsPerKm: 352, avgHeartRate: 153),
            RunSession.Split(kmNumber: 3, paceSecondsPerKm: 348, avgHeartRate: 156),
            RunSession.Split(kmNumber: 4, paceSecondsPerKm: 345, avgHeartRate: 160),
            RunSession.Split(kmNumber: 5, paceSecondsPerKm: 350, avgHeartRate: 158)
        ],
        gpsTrack: []
    )

    // MARK: - New Run Request

    static let newRunRequest = NewRunRequest(
        workoutId: "w1",
        startedAt: Date().addingTimeInterval(-2820),
        endedAt: Date(),
        distanceKm: 7.85, durationSeconds: 2820,
        avgPaceSecondsPerKm: 359, avgHeartRate: 148, maxHeartRate: 168,
        calories: 520, elevationGainMeters: 42,
        splits: runSession.splits,
        gpsTrack: runSession.gpsTrack
    )

    // MARK: - Community

    static let community = Community(
        id: "c1", tier: .momentum, name: "Momentum Runners",
        memberCount: 234,
        challenges: [
            Challenge(id: "ch1", title: "March Mileage", description: "Run 100 km this month", targetKm: 100, endDate: Date().addingTimeInterval(22 * 86400)),
            Challenge(id: "ch2", title: "Speed Week", description: "Complete 3 tempo runs", targetKm: 30, endDate: Date().addingTimeInterval(7 * 86400))
        ]
    )

    static let leaderboard: [LeaderboardEntry] = [
        LeaderboardEntry(id: "l1", userId: "u2", displayName: "Jordan Lee", weeklyDistanceKm: 52.3, rank: 1),
        LeaderboardEntry(id: "l2", userId: "u3", displayName: "Casey Park", weeklyDistanceKm: 45.8, rank: 2),
        LeaderboardEntry(id: "l3", userId: "u1", displayName: "Alex Runner", weeklyDistanceKm: 38.5, rank: 3),
        LeaderboardEntry(id: "l4", userId: "u4", displayName: "Sam Chen", weeklyDistanceKm: 32.1, rank: 4),
        LeaderboardEntry(id: "l5", userId: "u5", displayName: "Taylor Kim", weeklyDistanceKm: 28.7, rank: 5)
    ]

    static let friendActivity: [FriendActivity] = [
        FriendActivity(id: "fa1", userId: "u2", displayName: "Jordan Lee", distanceKm: 12.5, paceSecondsPerKm: 310, completedAt: Date().addingTimeInterval(-7200)),
        FriendActivity(id: "fa2", userId: "u3", displayName: "Casey Park", distanceKm: 8.0, paceSecondsPerKm: 345, completedAt: Date().addingTimeInterval(-18000)),
        FriendActivity(id: "fa3", userId: "u4", displayName: "Sam Chen", distanceKm: 5.5, paceSecondsPerKm: 380, completedAt: Date().addingTimeInterval(-43200))
    ]

    // MARK: - Community Runs

    static let communityRuns: [CommunityRun] = [
        CommunityRun(
            id: "cr1", name: "Golden Gate Park Loop",
            distanceKm: 10, date: Date().addingTimeInterval(5 * 86400),
            location: "Golden Gate Park, JFK Drive",
            city: "San Francisco",
            latitude: 37.7694, longitude: -122.4862,
            rsvpCount: 12, isRsvpdByUser: true
        ),
        CommunityRun(
            id: "cr2", name: "Embarcadero Sunrise Run",
            distanceKm: 5, date: Date().addingTimeInterval(8 * 86400),
            location: "Ferry Building",
            city: "San Francisco",
            latitude: 37.7955, longitude: -122.3937,
            rsvpCount: 8, isRsvpdByUser: false
        ),
        CommunityRun(
            id: "cr3", name: "Brooklyn Bridge 10K",
            distanceKm: 10, date: Date().addingTimeInterval(12 * 86400),
            location: "Brooklyn Bridge Park",
            city: "New York",
            latitude: 40.7061, longitude: -73.9969,
            rsvpCount: 25, isRsvpdByUser: false
        )
    ]
}
#endif
