//
//  Public+Model+CameraZoomLevel.swift
//  Pose
//
//  Created by Toan Nguyen on 24/8/25.
//

import AVFoundation
import Foundation

// MARK: - Public Camera Zoom Level Interface

public extension CameraZoomLevel {
    /// Returns the zoom factor as CGFloat for use with AVCaptureDevice
    var publicZoomFactor: CGFloat {
        zoomFactor
    }

    /// Returns true if this is an ultra wide camera
    var publicIsUltraWide: Bool {
        isUltraWide
    }

    /// Returns true if this is a wide angle camera
    var publicIsWide: Bool {
        isWide
    }

    /// Returns true if this is a telephoto camera
    var publicIsTelephoto: Bool {
        isTelephoto
    }

    /// Returns a user-friendly description of the zoom level
    var publicDescription: String {
        "\(displayName) - \(cameraType)"
    }
}
