//
//  UserPermission+Camera.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 11/9/25.
//

import AVFoundation
import Foundation

// MARK: - Camera

extension RealUserPermissionsInteractor {
    func cameraPermissionStatus() async -> Permission.Status {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return status.map
    }

    func requestCameraPermission() async {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            permissionStatuses[.camera] = status ? .granted : .denied
        }
    }
}

// MARK: - AVAuthorizationStatus Extension

extension AVAuthorizationStatus {
    var map: Permission.Status {
        switch self {
        case .notDetermined:
            return .notRequested
        case .restricted, .denied:
            return .denied
        case .authorized:
            return .granted
        @unknown default:
            return .unknown
        }
    }
}
