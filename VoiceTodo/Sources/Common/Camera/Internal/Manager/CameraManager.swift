//
//  CameraManager.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import AudioToolbox
import AVKit
import SwiftUI

@MainActor public class CameraManager: NSObject, ObservableObject {
    @Published var attributes: CameraManagerAttributes = .init()

    // MARK: Input

    private(set) var captureSession: any CaptureSession
    private(set) var frontCameraInput: (any CaptureDeviceInput)?
    private(set) var backCameraInput: (any CaptureDeviceInput)?
    private(set) var availableBackCameraInputs: [(any CaptureDeviceInput)?] = []

    // MARK: Output

    private(set) var photoOutput: CameraManagerPhotoOutput = .init()
    private(set) var videoOutput: CameraManagerVideoOutput = .init()

    // MARK: UI Elements

    private(set) var cameraView: UIView!
    private(set) var cameraLayer: AVCaptureVideoPreviewLayer = .init()
    private(set) var cameraMetalView: CameraMetalView = .init()
    private(set) var cameraGridView: CameraGridView = .init()

    // MARK: Others

    private(set) var permissionsManager: CameraManagerPermissionsManager = .init()
    private(set) var motionManager: CameraManagerMotionManager = .init()
    private(set) var notificationCenterManager: CameraManagerNotificationCenter = .init()
    private(set) var zoomManager: CameraZoomManager = .init()

    private let videoProcessingQueue = DispatchQueue(label: "com.camera.videoProcessing", qos: .userInteractive)
    
    // MARK: Initializer

    init<CDI: CaptureDeviceInput>(captureSession: some CaptureSession, captureDeviceInputType _: CDI.Type) {
        self.captureSession = captureSession
        frontCameraInput = CDI.get(mediaType: .video, position: .front)
        backCameraInput = CDI.get(mediaType: .video, position: .back)
    }
}

// MARK: Initialize

extension CameraManager {
    func initialize(in view: UIView) {
        cameraView = view
    }
}

// MARK: Setup

extension CameraManager {
    func setup() async throws(MCameraError) {
        try await permissionsManager.requestAccess(parent: self)

        setupCameraLayer()
        await setupAvailableBackCameraInputs()
        try setupDeviceInputs()
        try setupDeviceOutput()
        try setupFrameRecorder()
        notificationCenterManager.setup(parent: self)
        motionManager.setup(parent: self)
        try cameraMetalView.setup(parent: self)
        cameraGridView.setup(parent: self)

        startSession()
    }
}

private extension CameraManager {
    func setupAvailableBackCameraInputs() async {
        // Wait for zoom manager to finish loading
        while zoomManager.isCurrentlyLoading {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }

        // Get device types from zoom levels
        let supportedDeviceTypes = zoomManager.availableZoomLevels.map(\.deviceType)

        // Create discovery session with supported device types
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: supportedDeviceTypes,
            mediaType: .video,
            position: .back
        )

        // Get the capture device input type from the existing backCameraInput
        guard let backCameraInput else { return }
        let captureDeviceInputType = type(of: backCameraInput)

        // Create camera inputs for each available back camera device
        availableBackCameraInputs = discoverySession.devices.map { device in
            // Create input using the standard get method
//            captureDeviceInputType.get(mediaType: .video, position: .back)
            captureDeviceInputType.get(deviceType: device.deviceType, mediaType: .video, position: .back)
        }
    }

    func setupCameraLayer() {
        captureSession.sessionPreset = attributes.resolution

        cameraLayer.session = captureSession as? AVCaptureSession
        cameraLayer.videoGravity = .resizeAspectFill
        cameraLayer.isHidden = true
        cameraView.layer.addSublayer(cameraLayer)
    }

    func setupDeviceInputs() throws(MCameraError) {
        try captureSession.add(input: getCameraInput())
        if let audioInput = getAudioInput() { try captureSession.add(input: audioInput) }
    }

    func setupDeviceOutput() throws(MCameraError) {
        try photoOutput.setup(parent: self)
        try videoOutput.setup(parent: self)
    }

    func setupFrameRecorder() throws(MCameraError) {
        let captureVideoOutput = AVCaptureVideoDataOutput()
        captureVideoOutput.setSampleBufferDelegate(cameraMetalView, queue: videoProcessingQueue)

        try captureSession.add(output: captureVideoOutput)
    }

    func startSession() { Task {
        guard let device = getCameraInput()?.device else { return }

        try await startCaptureSession()
        try setupDevice(device)
        resetAttributes(device: device)
        cameraMetalView.performCameraEntranceAnimation()
    }}
}

private extension CameraManager {
    func getAudioInput() -> (any CaptureDeviceInput)? {
        guard attributes.isAudioSourceAvailable,
              let deviceInput = frontCameraInput ?? backCameraInput
        else { return nil }

        let captureDeviceInputType = type(of: deviceInput)
        let audioInput = captureDeviceInputType.get(mediaType: .audio, position: .unspecified)
        return audioInput
    }

    nonisolated func startCaptureSession() async throws {
        await captureSession.startRunning()
    }

    func setupDevice(_ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setExposureMode(
            attributes.cameraExposure.mode,
            duration: attributes.cameraExposure.duration,
            iso: attributes.cameraExposure.iso
        )
        device.setExposureTargetBias(attributes.cameraExposure.targetBias)
        device.setFrameRate(attributes.frameRate)
        device.setZoomFactor(attributes.zoomFactor)
        device.setLightMode(attributes.lightMode)
        device.hdrMode = attributes.hdrMode
        device.unlockForConfiguration()
    }
}

// MARK: Cancel

extension CameraManager {
    func cancel() {
        captureSession = captureSession.stopRunningAndReturnNewInstance()
        motionManager.reset()
        photoOutput.reset()
        videoOutput.reset()
        notificationCenterManager.reset()
    }
}

// MARK: - LIVE ACTIONS

// MARK: Loading
extension CameraManager {
    func startLoading() {
        attributes.loading = true
    }
    func stopLoading() {
        attributes.loading = false
    }
}

// MARK: Capture Output

extension CameraManager {
    func captureOutput() {
        guard !isChanging else { return }

        switch attributes.outputType {
        case .photo: photoOutput.capture()
        case .video: videoOutput.toggleRecording()
        }
    }
}

// MARK: Set Captured Media

extension CameraManager {
    func setCapturedMedia(_ capturedMedia: MCameraMedia?) { withAnimation(.mSpring) {
        attributes.capturedMedia = capturedMedia
    }}
}

// MARK: Set Camera Output

extension CameraManager {
    func setOutputType(_ outputType: CameraOutputType) {
        guard outputType != attributes.outputType, !isChanging else { return }
        attributes.outputType = outputType
    }
}

// MARK: Set Camera Position

extension CameraManager {
    func setCameraPosition(_ position: CameraPosition) async throws {
        guard position != attributes.cameraPosition, !isChanging else { return }

        await cameraMetalView.beginCameraFlipAnimation()
        try changeCameraInput(position)
        resetAttributesWhenChangingCamera(position)
        await cameraMetalView.finishCameraFlipAnimation()
    }
}

// MARK: Set Camera Device Type

extension CameraManager {
    func setCameraDeviceType(_ deviceType: AVCaptureDevice.DeviceType) async throws {
        // Only apply for back camera position
        guard attributes.cameraPosition == .back, !isChanging else { return }

        // Check if device type exists in available back camera inputs
        guard let newInput = getBackCameraInput(for: deviceType) else { return }

        // Check if we're already using this device type
        guard getCurrentDeviceType() != deviceType else { return }

//        await cameraMetalView.beginCameraFlipAnimation()
        try changeCameraInputByDeviceType(deviceType)
        resetAttributesWhenChangingCameraDevice(deviceType)
        await cameraMetalView.finishCameraFlipAnimation()
    }
}

private extension CameraManager {
    func changeCameraInput(_ position: CameraPosition) throws {
        if let input = getCameraInput() { captureSession.remove(input: input) }
        try captureSession.add(input: getCameraInput(position))
    }

    func resetAttributesWhenChangingCamera(_ position: CameraPosition) {
        resetAttributes(device: getCameraInput(position)?.device)
        attributes.cameraPosition = position
    }

    func changeCameraInputByDeviceType(_ deviceType: AVCaptureDevice.DeviceType) throws {
        // Remove current back camera input
        if let currentInput = backCameraInput {
            captureSession.remove(input: currentInput)
        }

        // Get new input for the specified device type
        guard let newInput = getBackCameraInput(for: deviceType) else { return }

        // Add new input to session
        try captureSession.add(input: newInput)

        // Update backCameraInput reference
        backCameraInput = newInput
    }

    func resetAttributesWhenChangingCameraDevice(_ deviceType: AVCaptureDevice.DeviceType) {
        // Reset attributes based on the new device
        if let newInput = getBackCameraInput(for: deviceType) {
            resetAttributes(device: newInput.device)
        }
    }
}

// MARK: Set Camera Zoom

extension CameraManager {
    func setCameraZoomFactor(_ zoomFactor: CGFloat) throws {
        guard let device = getCameraInput()?.device, zoomFactor != attributes.zoomFactor, !isChanging else { return }

        try setDeviceZoomFactor(zoomFactor, device)
        attributes.zoomFactor = device.videoZoomFactor
    }
}

private extension CameraManager {
    func setDeviceZoomFactor(_ zoomFactor: CGFloat, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setZoomFactor(zoomFactor)
        device.unlockForConfiguration()
    }
}

// MARK: Set Camera Focus

extension CameraManager {
    func setCameraFocus(at touchPoint: CGPoint) throws {
        guard let device = getCameraInput()?.device, !isChanging else { return }

        let focusPoint = convertTouchPointToFocusPoint(touchPoint)
        try setDeviceCameraFocus(focusPoint, device)
        cameraMetalView.performCameraFocusAnimation(touchPoint: touchPoint)
    }
}

private extension CameraManager {
    func convertTouchPointToFocusPoint(_ touchPoint: CGPoint) -> CGPoint { .init(
        x: touchPoint.y / cameraView.frame.height,
        y: 1 - touchPoint.x / cameraView.frame.width
    ) }
    func setDeviceCameraFocus(_ focusPoint: CGPoint, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setFocusPointOfInterest(focusPoint)
        device.setExposurePointOfInterest(focusPoint)
        device.unlockForConfiguration()
    }
}

// MARK: Set Flash Mode

extension CameraManager {
    func setFlashMode(_ flashMode: CameraFlashMode) {
        guard let device = getCameraInput()?.device, device.hasFlash, flashMode != attributes.flashMode,
              !isChanging else { return }
        attributes.flashMode = flashMode
    }
}

// MARK: Set Light Mode

extension CameraManager {
    func setLightMode(_ lightMode: CameraLightMode) throws {
        guard let device = getCameraInput()?.device, device.hasTorch, lightMode != attributes.lightMode,
              !isChanging else { return }

        try setDeviceLightMode(lightMode, device)
        attributes.lightMode = device.lightMode
    }
}

private extension CameraManager {
    func setDeviceLightMode(_ lightMode: CameraLightMode, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setLightMode(lightMode)
        device.unlockForConfiguration()
    }
}

// MARK: Set Mirror Output

extension CameraManager {
    func setMirrorOutput(_ mirrorOutput: Bool) {
        guard mirrorOutput != attributes.mirrorOutput, !isChanging else { return }
        attributes.mirrorOutput = mirrorOutput
    }
}

// MARK: Set Grid Visibility

extension CameraManager {
    func setGridVisibility(_ isGridVisible: Bool) {
        guard isGridVisible != attributes.isGridVisible, !isChanging else { return }
        cameraGridView.setVisibility(isGridVisible)
    }
}

// MARK: Set Camera Filters

extension CameraManager {
    func setCameraFilters(_ cameraFilters: [CIFilter]) {
        guard cameraFilters != attributes.cameraFilters, !isChanging else { return }
        attributes.cameraFilters = cameraFilters
    }
}

// MARK: Set Exposure Mode

extension CameraManager {
    func setExposureMode(_ exposureMode: AVCaptureDevice.ExposureMode) throws {
        guard let device = getCameraInput()?.device, exposureMode != attributes.cameraExposure.mode,
              !isChanging else { return }

        try setDeviceExposureMode(exposureMode, device)
        attributes.cameraExposure.mode = device.exposureMode
    }
}

private extension CameraManager {
    func setDeviceExposureMode(_ exposureMode: AVCaptureDevice.ExposureMode, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setExposureMode(
            exposureMode,
            duration: attributes.cameraExposure.duration,
            iso: attributes.cameraExposure.iso
        )
        device.unlockForConfiguration()
    }
}

// MARK: Set Exposure Duration

extension CameraManager {
    func setExposureDuration(_ exposureDuration: CMTime) throws {
        guard let device = getCameraInput()?.device, exposureDuration != attributes.cameraExposure.duration,
              !isChanging else { return }

        try setDeviceExposureDuration(exposureDuration, device)
        attributes.cameraExposure.duration = device.exposureDuration
    }
}

private extension CameraManager {
    func setDeviceExposureDuration(_ exposureDuration: CMTime, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setExposureMode(.custom, duration: exposureDuration, iso: attributes.cameraExposure.iso)
        device.unlockForConfiguration()
    }
}

// MARK: Set ISO

extension CameraManager {
    func setISO(_ iso: Float) throws {
        guard let device = getCameraInput()?.device, iso != attributes.cameraExposure.iso, !isChanging else { return }

        try setDeviceISO(iso, device)
        attributes.cameraExposure.iso = device.iso
    }
}

private extension CameraManager {
    func setDeviceISO(_ iso: Float, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setExposureMode(.custom, duration: attributes.cameraExposure.duration, iso: iso)
        device.unlockForConfiguration()
    }
}

// MARK: Set Exposure Target Bias

extension CameraManager {
    func setExposureTargetBias(_ exposureTargetBias: Float) throws {
        guard let device = getCameraInput()?.device, exposureTargetBias != attributes.cameraExposure.targetBias,
              !isChanging else { return }

        try setDeviceExposureTargetBias(exposureTargetBias, device)
        attributes.cameraExposure.targetBias = device.exposureTargetBias
    }
}

private extension CameraManager {
    func setDeviceExposureTargetBias(_ exposureTargetBias: Float, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setExposureTargetBias(exposureTargetBias)
        device.unlockForConfiguration()
    }
}

// MARK: Set HDR Mode

extension CameraManager {
    func setHDRMode(_ hdrMode: CameraHDRMode) throws {
        guard let device = getCameraInput()?.device, hdrMode != attributes.hdrMode, !isChanging else { return }

        try setDeviceHDRMode(hdrMode, device)
        attributes.hdrMode = hdrMode
    }
}

private extension CameraManager {
    func setDeviceHDRMode(_ hdrMode: CameraHDRMode, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.hdrMode = hdrMode
        device.unlockForConfiguration()
    }
}

// MARK: Set Resolution

extension CameraManager {
    func setResolution(_ resolution: AVCaptureSession.Preset) {
        guard resolution != attributes.resolution, resolution != attributes.resolution, !isChanging else { return }

        captureSession.sessionPreset = resolution
        attributes.resolution = resolution
    }
}

// MARK: Set Frame Rate

extension CameraManager {
    func setFrameRate(_ frameRate: Int32) throws {
        guard let device = getCameraInput()?.device, frameRate != attributes.frameRate, !isChanging else { return }

        try setDeviceFrameRate(frameRate, device)
        attributes.frameRate = device.activeVideoMaxFrameDuration.timescale
    }
}

private extension CameraManager {
    func setDeviceFrameRate(_ frameRate: Int32, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setFrameRate(frameRate)
        device.unlockForConfiguration()
    }
}

// MARK: Set Capture Delay

extension CameraManager {
    func setCaptureDelay(_ captureDelay: CaptureDelay) {
        guard captureDelay != attributes.captureDelay, !isChanging else { return }
        attributes.captureDelay = captureDelay
    }
}

// MARK: Set Image Aspect Ratio

extension CameraManager {
    func setImageAspectRatio(_ imageAspectRatio: ImageAspectRatio) {
        guard imageAspectRatio != attributes.imageAspectRatio, !isChanging else { return }
        attributes.imageAspectRatio = imageAspectRatio
    }
}

// MARK: Set Sound

extension CameraManager {
    func setSound(_ sound: Sound) {
        guard sound != attributes.sound, !isChanging else { return }
        attributes.sound = sound
    }
}

// MARK: Set Focus

extension CameraManager {
    func setFocus(_ focus: Focus) {
        guard focus != attributes.focus, !isChanging else { return }
        attributes.focus = focus
    }
}

// MARK: Set Mirror

extension CameraManager {
    func setMirror(_ mirror: MirrorType) {
        guard mirror != attributes.mirror, !isChanging else { return }
        setMirrorOutput(mirror == .on)
        attributes.mirror = mirror
    }
}

// MARK: Set Vibrate

extension CameraManager {
    func setVibrate(_ vibrate: Vibrate) {
        guard vibrate != attributes.vibrate, !isChanging else { return }
        attributes.vibrate = vibrate
    }
}

// MARK: Set Grid

extension CameraManager {
    func setGrid(_ grid: Grid) {
        guard grid != attributes.grid, !isChanging else { return }
        attributes.grid = grid
        cameraGridView.setGrid(grid)
    }
}

// MARK: - HELPERS

// MARK: Attributes

extension CameraManager {
    var hasFlash: Bool { getCameraInput()?.device.hasFlash ?? false }
    var hasLight: Bool { getCameraInput()?.device.hasTorch ?? false }
}

private extension CameraManager {
    var isChanging: Bool { cameraMetalView.isAnimating }
}

// MARK: Methods

extension CameraManager {
    func resetAttributes(device: (any CaptureDevice)?) {
        guard let device else { return }

        var newAttributes = attributes
        newAttributes.cameraExposure.mode = device.exposureMode
        newAttributes.cameraExposure.duration = device.exposureDuration
        newAttributes.cameraExposure.iso = device.iso
        newAttributes.cameraExposure.targetBias = device.exposureTargetBias
        newAttributes.frameRate = device.activeVideoMaxFrameDuration.timescale
        newAttributes.zoomFactor = device.videoZoomFactor
        newAttributes.lightMode = device.lightMode
        newAttributes.hdrMode = device.hdrMode

        attributes = newAttributes
    }

    func getCameraInput(_ position: CameraPosition? = nil) -> (any CaptureDeviceInput)? { switch position ?? attributes
        .cameraPosition {
        case .front: frontCameraInput
        case .back: backCameraInput
        }
    }
}

// MARK: Available Back Camera Inputs

extension CameraManager {
    /// Returns all available back camera inputs on this device
    func getAvailableBackCameraInputs() -> [(any CaptureDeviceInput)?] {
        availableBackCameraInputs
    }

    /// Returns the device types of all available back camera inputs
    func getAvailableBackCameraDeviceTypes() -> [AVCaptureDevice.DeviceType] {
        availableBackCameraInputs.compactMap { $0?.device.deviceType }
    }

    /// Returns the current device type of the active camera
    func getCurrentDeviceType() -> AVCaptureDevice.DeviceType? {
        getCameraInput()?.device.deviceType
    }

    /// Returns a specific back camera input by device type
    func getBackCameraInput(for deviceType: AVCaptureDevice.DeviceType) -> (any CaptureDeviceInput)? {
        availableBackCameraInputs.first { $0?.device.deviceType == deviceType } ?? nil
    }

    /// Switches to a specific back camera input by device type
    func switchToBackCameraInput(for deviceType: AVCaptureDevice.DeviceType) throws {
        guard let newInput = getBackCameraInput(for: deviceType) else { return }

        // Remove current back camera input if exists
        if let currentInput = backCameraInput {
            captureSession.remove(input: currentInput)
        }

        // Add new input
        try captureSession.add(input: newInput)
        backCameraInput = newInput
    }
}

// MARK: Zoom Levels

extension CameraManager {
    /// Returns the available zoom levels for the current device
    var availableZoomLevels: [CameraZoomLevel] {
        zoomManager.availableZoomLevels
    }

    /// Returns the device information string
    var deviceInformation: String {
        zoomManager.deviceInformation
    }

    /// Returns true if the zoom manager is currently loading
    var isZoomManagerLoading: Bool {
        zoomManager.isCurrentlyLoading
    }

    /// Returns the current error message from zoom manager if any
    var zoomManagerErrorMessage: String? {
        zoomManager.currentErrorMessage
    }

    /// Refreshes the zoom levels detection
    func refreshZoomLevels() async {
        await zoomManager.refreshZoomLevels()
        // Also refresh available back camera inputs when zoom levels are refreshed
        await setupAvailableBackCameraInputs()
    }
}
