//
//  LocationService.swift
//  recon
//
//  Created by Ethan Chen on 12/4/2024.
//

import CoreLocation
import Combine
import Foundation

/// One-shot location lookups for the screens that need a fix before they can
/// ask the server for places.
@MainActor
final class LocationService: NSObject, ObservableObject {

    // MARK: - Properties

    static let shared = LocationService()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()

    /// Every caller waiting on the current lookup.
    ///
    /// A list, not a single completion: Home asks for a location on appear,
    /// and starting a party straight afterwards asks again before the first
    /// lookup resolves. Both callers have to hear back.
    private var pending: [(Result<CLLocation, Error>) -> Void] = []

    private var timeout: DispatchWorkItem?
    private var hasRequestedPermission = false

    /// How long a fix stays good enough to reuse.
    private static let freshness: TimeInterval = 300

    /// How long to wait before giving up on a fix.
    ///
    /// CoreLocation is not guaranteed to call back at all: indoors, in
    /// airplane mode, or on a simulator with no location set, neither
    /// `didUpdateLocations` nor `didFailWithError` arrives. Without this the
    /// caller's completion is never called and the screen sits on its spinner
    /// with no error and no way out but Back.
    private static let deadline: TimeInterval = 8

    // MARK: - Errors

    enum LocationError: LocalizedError {
        case denied
        case timedOut

        var errorDescription: String? {
            switch self {
            case .denied:
                return "RecOn needs location access to find places near you."
            case .timedOut:
                return "Couldn't get your location. Check that location services are on and try again."
            }
        }
    }

    // MARK: - Init

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        /// Seed from the manager: callers that only read this property would
        /// otherwise see notDetermined until the first delegate callback, and
        /// conclude permission was never granted.
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Functions

    func requestLocationPermission() {
        hasRequestedPermission = true
        locationManager.requestWhenInUseAuthorization()
    }

    /// Resolves with a fix, or fails. The completion is always called.
    func getCurrentLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        let status = locationManager.authorizationStatus
        authorizationStatus = status

        switch status {
        case .notDetermined:
            /// Wait on the authorization callback rather than re-polling every
            /// half second, which never stopped if the prompt went unanswered.
            pending.append(completion)
            armDeadline()

            if !hasRequestedPermission {
                requestLocationPermission()
            }

        case .authorizedWhenInUse, .authorizedAlways:
            if let location = currentLocation,
               location.timestamp.timeIntervalSinceNow > -Self.freshness {
                completion(.success(location))
                return
            }

            pending.append(completion)
            armDeadline()
            locationManager.requestLocation()

        default:
            completion(.failure(LocationError.denied))
        }
    }

    // MARK: - Private

    private func armDeadline() {
        guard timeout == nil else { return }

        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                self?.resolve(.failure(LocationError.timedOut))
            }
        }
        timeout = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.deadline, execute: work)
    }

    private func resolve(_ result: Result<CLLocation, Error>) {
        timeout?.cancel()
        timeout = nil

        let waiting = pending
        pending = []
        waiting.forEach { $0(result) }
    }

}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.first else { return }
            currentLocation = location
            resolve(.success(location))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            resolve(.failure(error))
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        /// Read through our own manager rather than the one handed in: it is
        /// the same object, and CLLocationManager is not Sendable, so crossing
        /// the actor boundary with the parameter is a data race in Swift 6.
        Task { @MainActor in
            let status = locationManager.authorizationStatus
            authorizationStatus = status

            guard !pending.isEmpty else { return }

            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                locationManager.requestLocation()
            case .denied, .restricted:
                resolve(.failure(LocationError.denied))
            default:
                break
            }
        }
    }

}
