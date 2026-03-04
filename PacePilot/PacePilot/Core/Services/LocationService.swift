import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published private(set) var currentPaceSecondsPerKm: Double = 0
    @Published private(set) var distanceKm: Double = 0
    @Published private(set) var gpsTrack: [RunSession.GPSPoint] = []

    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var isTracking = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 5
        manager.activityType = .fitness
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
    }

    func requestAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func startTracking() {
        isTracking = true
        distanceKm = 0
        gpsTrack = []
        lastLocation = nil
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        isTracking = false
        manager.stopUpdatingLocation()
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking, let location = locations.last else { return }
        let point = RunSession.GPSPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            timestamp: location.timestamp
        )
        gpsTrack.append(point)

        if let last = lastLocation {
            let delta = location.distance(from: last) / 1000.0
            distanceKm += delta
        }
        lastLocation = location

        // Pace from CLLocation speed (m/s)
        if location.speed > 0.5 {
            currentPaceSecondsPerKm = 1000.0 / location.speed
        }
    }
}
