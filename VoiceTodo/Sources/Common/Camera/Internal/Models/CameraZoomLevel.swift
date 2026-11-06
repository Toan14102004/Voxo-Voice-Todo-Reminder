//
//  CameraZoomLevel.swift
//  Pose
//
//  Created by Toan Nguyen on 24/8/25.
//

import AVFoundation
import Foundation

public struct CameraZoomLevel: Identifiable, Hashable {
    public let id = UUID()
    public let factor: Double
    public let cameraType: String
    public let deviceType: AVCaptureDevice.DeviceType

    public var displayName: String {
        if factor == 0.5 {
            "0.5x (Ultra Wide)"
        } else if factor == 1.0 {
            "1x (Wide)"
        } else if factor >= 2.0 {
            "\(factor == floor(factor) ? String(format: "%.0f", factor) : String(factor))x (Telephoto)"
        } else {
            "\(factor)x"
        }
    }

    public init(factor: Double, cameraType: String, deviceType: AVCaptureDevice.DeviceType) {
        self.factor = factor
        self.cameraType = cameraType
        self.deviceType = deviceType
    }
}

// MARK: - Camera Zoom Level Extensions

public extension CameraZoomLevel {
    /// Returns the zoom factor as CGFloat for use with AVCaptureDevice
    var zoomFactor: CGFloat {
        CGFloat(factor)
    }

    /// Returns true if this is an ultra wide camera
    var isUltraWide: Bool {
        deviceType == .builtInUltraWideCamera
    }

    /// Returns true if this is a wide angle camera
    var isWide: Bool {
        deviceType == .builtInWideAngleCamera
    }

    /// Returns true if this is a telephoto camera
    var isTelephoto: Bool {
        deviceType == .builtInTelephotoCamera
    }
}
