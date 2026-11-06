//
//  UserPermission+Location.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 11/9/25.
//

import CoreLocation
import Foundation

// MARK: - Location

extension RealUserPermissionsInteractor {
    func locationPermissionStatus() async -> Permission.Status {
        let status = CLLocationManager.authorizationStatus()
        return status.map
    }

    func requestLocationPermission() async {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()

        // Wait a bit for the authorization status to update
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let status = CLLocationManager.authorizationStatus()
        await MainActor.run {
            permissionStatuses[.location] = status.map
        }
    }
}

// MARK: - CLAuthorizationStatus Extension

extension CLAuthorizationStatus {
    var map: Permission.Status {
        switch self {
        case .notDetermined:
            return .notRequested
        case .restricted, .denied:
            return .denied
        case .authorizedWhenInUse, .authorizedAlways:
            return .granted
        @unknown default:
            return .unknown
        }
    }
}
