//
//  UserPermission+PhotoLibrary.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 15/2/25.
//

import Foundation
import Photos

protocol SystemPhotoLibraryCenter {
    func currentSettings(for accessLevel: PHAccessLevel) async -> PHAuthorizationStatus
    func requestAuthorization(for accessLevel: PHAccessLevel) async throws -> Permission.Status
}

extension PHPhotoLibrary: SystemPhotoLibraryCenter {
    func currentSettings(for accessLevel: PHAccessLevel) -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: accessLevel)
    }

    func requestAuthorization(for accessLevel: PHAccessLevel) async -> Permission.Status {
        let status = await PHPhotoLibrary.requestAuthorization(for: accessLevel)
        return status.map
    }
}

extension PHAuthorizationStatus {
    var map: Permission.Status {
        switch self {
        case .authorized, .limited: return .granted
        case .denied, .restricted: return .denied
        case .notDetermined: return .notRequested
        @unknown default: return .notRequested
        }
    }
}
