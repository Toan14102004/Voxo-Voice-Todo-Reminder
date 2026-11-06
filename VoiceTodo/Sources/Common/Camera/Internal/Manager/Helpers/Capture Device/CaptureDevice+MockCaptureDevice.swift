//
//  CaptureDevice+MockCaptureDevice.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import AVKit

class MockCaptureDevice: NSObject, CaptureDevice {
    // MARK: Getters

    var uniqueID: String = UUID().uuidString
    var exposureDuration: CMTime { _exposureDuration }
    var exposureTargetBias: Float { _exposureTargetBias }
    var iso: Float { _iso }
    var minAvailableVideoZoomFactor: CGFloat { 0.5 }
    var maxAvailableVideoZoomFactor: CGFloat { 10.0 }
    var minExposureDuration: CMTime { .init(value: 1, timescale: 1000) }
    var maxExposureDuration: CMTime { .init(value: 1, timescale: 5) }
    var minISO: Float { 1 }
    var maxISO: Float { 10 }
    var minExposureTargetBias: Float { 0.1 }
    var maxExposureTargetBias: Float { 199 }
    var minFrameRate: Float64? { 15 }
    var maxFrameRate: Float64? { 60 }
    var hasFlash: Bool { true }
    var hasTorch: Bool { true }
    var isExposurePointOfInterestSupported: Bool { true }
    var isFocusPointOfInterestSupported: Bool { true }
    var deviceType: AVCaptureDevice.DeviceType { .builtInWideAngleCamera }

    // MARK: Setters

    var videoZoomFactor: CGFloat = 1
    var focusMode: AVCaptureDevice.FocusMode = .autoFocus
    var focusPointOfInterest: CGPoint = .zero
    var exposurePointOfInterest: CGPoint = .zero
    var lightMode: CameraLightMode = .off
    var activeVideoMinFrameDuration: CMTime = .init()
    var activeVideoMaxFrameDuration: CMTime = .init()
    var exposureMode: AVCaptureDevice.ExposureMode = .continuousAutoExposure
    var hdrMode: CameraHDRMode = .auto

    // MARK: Methods

    func lockForConfiguration() throws {}
    func unlockForConfiguration() {}
    func isExposureModeSupported(_: AVCaptureDevice.ExposureMode) -> Bool { true }
    func setExposureModeCustom(duration: CMTime, iso: Float, completionHandler _: ((CMTime) -> Void)?) {
        _exposureDuration = duration
        _iso = iso
    }

    func setExposureTargetBias(_ bias: Float, completionHandler _: ((CMTime) -> Void)?) {
        _exposureTargetBias = bias
    }

    // MARK: Private Attributes

    private var _exposureDuration: CMTime = .init()
    private var _exposureTargetBias: Float = 0
    private var _iso: Float = 0
}
