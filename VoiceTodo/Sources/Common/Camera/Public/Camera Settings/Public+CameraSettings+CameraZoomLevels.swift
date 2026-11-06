//
//  Public+CameraSettings+CameraZoomLevels.swift
//  Pose
//
//  Created by Toan Nguyen on 24/8/25.
//

import AVFoundation
import Foundation

// MARK: - Public Camera Zoom Levels Interface

public extension CameraManager {
    /// Returns the available zoom levels for the current device
    var publicAvailableZoomLevels: [CameraZoomLevel] {
        availableZoomLevels
    }

    /// Returns the device information string
    var publicDeviceInformation: String {
        deviceInformation
    }

    /// Returns true if the zoom manager is currently loading
    var publicIsZoomManagerLoading: Bool {
        isZoomManagerLoading
    }

    /// Returns the current error message from zoom manager if any
    var publicZoomManagerErrorMessage: String? {
        zoomManagerErrorMessage
    }

    /// Refreshes the zoom levels detection
    func publicRefreshZoomLevels() async {
        await refreshZoomLevels()
    }

    /// Returns zoom levels filtered by camera type
    func publicGetZoomLevels(by cameraType: String) -> [CameraZoomLevel] {
        availableZoomLevels.filter { $0.cameraType == cameraType }
    }

    /// Returns zoom levels filtered by device type
    func publicGetZoomLevels(by deviceType: AVCaptureDevice.DeviceType) -> [CameraZoomLevel] {
        availableZoomLevels.filter { $0.deviceType == deviceType }
    }

    /// Returns the closest zoom level to the specified factor
    func publicGetClosestZoomLevel(to factor: Double) -> CameraZoomLevel? {
        availableZoomLevels.min { abs($0.factor - factor) < abs($1.factor - factor) }
    }

    /// Returns zoom levels within a specific range
    func publicGetZoomLevels(in range: ClosedRange<Double>) -> [CameraZoomLevel] {
        availableZoomLevels.filter { range.contains($0.factor) }
    }
}
