//
//  UserPermission+Microphone.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 23/12/25.
//

import AVFoundation
import Foundation

// MARK: - Microphone

extension RealUserPermissionsInteractor {
    func microphonePermissionStatus() async -> Permission.Status {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        return status.map
    }

    func requestMicrophonePermission() async {
        let status = await AVCaptureDevice.requestAccess(for: .audio)
        await MainActor.run {
            permissionStatuses[.microphone] = status ? .granted : .denied
        }
    }
}
