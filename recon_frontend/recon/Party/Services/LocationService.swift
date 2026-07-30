//
//  LocationService.swift
//  recon
//
//  Created by Ethan Chen on 12/4/2024.
//

import Foundation
import CoreLocation
import Combine

@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func getCurrentLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        let currentAuthStatus = locationManager.authorizationStatus
        authorizationStatus = currentAuthStatus
        
        if currentAuthStatus == .notDetermined {
            requestLocationPermission()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.getCurrentLocation(completion: completion)
            }
            return
        }
        
        guard currentAuthStatus == .authorizedWhenInUse || currentAuthStatus == .authorizedAlways else {
            
            completion(.failure(NSError(domain: "LocationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Location permission not granted"])))
            return
        }
        
        if let location = currentLocation,
           location.timestamp.timeIntervalSinceNow > -300 {
            
            completion(.success(location))
            return
        }
        
        
        locationManager.requestLocation()
        locationCompletion = completion
    }
    
    private var locationCompletion: ((Result<CLLocation, Error>) -> Void)?
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            if let location = locations.first {
                self.currentLocation = location
                if let completion = self.locationCompletion {
                    completion(.success(location))
                    self.locationCompletion = nil
                }
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let completion = self.locationCompletion {
                completion(.failure(error))
                self.locationCompletion = nil
            }
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }
}
