//
//  CameraManager+PhotoOutput.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import AVKit

@MainActor class CameraManagerPhotoOutput: NSObject {
    private(set) var parent: CameraManager?
    private(set) var output: AVCapturePhotoOutput = .init()
    private(set) var isSetupComplete: Bool = false
    private var pendingCaptureRequests: [() -> Void] = []
}

// MARK: Setup

extension CameraManagerPhotoOutput {
    func setup(parent: CameraManager) throws(MCameraError) {
        self.parent = parent
        try parent.captureSession.add(output: output)
        
        // Mark setup as complete and process any pending capture requests
        isSetupComplete = true
        processPendingCaptureRequests()
    }
}

// MARK: - CAPTURE PHOTO

// MARK: Capture

extension CameraManagerPhotoOutput {
    func capture() {
        guard isSetupComplete else {
            
            if pendingCaptureRequests.count < 3 {
                pendingCaptureRequests.append { [weak self] in
                    self?.capture()
                }
            }
            return
        }
        
        guard let parent = parent else {
            return
        }
        
        let settings = getPhotoOutputSettings()

        configureOutput()
        output.capturePhoto(with: settings, delegate: self)
        parent.cameraMetalView.performImageCaptureAnimation()
    }
}

private extension CameraManagerPhotoOutput {
    func getPhotoOutputSettings() -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings()
        
        guard let parent = parent else {
            settings.flashMode = .off
            return settings
        }
        
        settings.flashMode = parent.attributes.flashMode.toDeviceFlashMode()
        return settings
    }

    func configureOutput() {
        guard let connection = output.connection(with: .video), connection.isVideoMirroringSupported else { return }
        
        guard let parent = parent else {
            return
        }

        connection.isVideoMirrored = parent.attributes.mirrorOutput ? parent.attributes
            .cameraPosition != .front : parent.attributes.cameraPosition == .front
        connection.videoOrientation = parent.attributes.deviceOrientation
    }
}

// MARK: Receive Data

extension CameraManagerPhotoOutput: @preconcurrency AVCapturePhotoCaptureDelegate {
    func photoOutput(_: AVCapturePhotoOutput, willCapturePhotoFor _: AVCaptureResolvedPhotoSettings) {
        guard let parent = parent else {
            return
        }
        
        if parent.attributes.sound == .off {
            AudioServicesDisposeSystemSoundID(1108)
        }
    }

    func photoOutput(_: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error _: (any Error)?) {
        guard let imageData = photo.fileDataRepresentation(),
              let ciImage = CIImage(data: imageData)
        else { return }
        
        guard let parent = parent else {
            return
        }

        let capturedCIImage = prepareCIImage(ciImage, parent.attributes.cameraFilters)
        var capturedCGImage = prepareCGImage(capturedCIImage)
        if let cgImage = capturedCGImage {
            capturedCGImage = cropCGImageToCameraViewAspect(cgImage)
        }
        let capturedUIImage = prepareUIImage(capturedCGImage)
        let capturedMedia = MCameraMedia(data: capturedUIImage)

        parent.setCapturedMedia(capturedMedia)
    }
}

private extension CameraManagerPhotoOutput {
    func prepareCIImage(_ ciImage: CIImage, _ filters: [CIFilter]) -> CIImage {
        ciImage.applyingFilters(filters)
    }

    func prepareCGImage(_ ciImage: CIImage) -> CGImage? {
        CIContext().createCGImage(ciImage, from: ciImage.extent)
    }

    func prepareUIImage(_ cgImage: CGImage?) -> UIImage? {
        guard let cgImage else { return nil }

        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
        return uiImage
    }
}

private extension CameraManagerPhotoOutput {
    func cropCGImageToCameraViewAspect(_ cgImage: CGImage) -> CGImage? {
        guard let parent = parent else {
            return cgImage
        }
        
        let viewSize = parent.cameraView?.bounds.size ?? .zero
        guard viewSize.width > 0, viewSize.height > 0 else { return cgImage }

        let targetAspect = viewSize.height / viewSize.width
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let imageAspect = imageWidth / imageHeight

        var cropWidth = imageWidth
        var cropHeight = imageHeight
        if imageAspect > targetAspect {
            cropWidth = imageHeight * targetAspect
        } else {
            cropHeight = imageWidth / targetAspect
        }

        let cropX = (imageWidth - cropWidth) / 2.0
        let cropY = (imageHeight - cropHeight) / 2.0
        let cropRect = CGRect(
            x: floor(cropX),
            y: floor(cropY),
            width: floor(cropWidth),
            height: floor(cropHeight)
        )

        return cgImage.cropping(to: cropRect) ?? cgImage
    }
}

// MARK: - Pending Capture Requests

private extension CameraManagerPhotoOutput {
    func processPendingCaptureRequests() {
        
        // Execute all pending capture requests
        for captureRequest in pendingCaptureRequests {
            captureRequest()
        }
        
        // Clear the queue
        pendingCaptureRequests.removeAll()
    }
}

// MARK: Reset

extension CameraManagerPhotoOutput {
    func reset() {
        isSetupComplete = false
        parent = nil
        pendingCaptureRequests.removeAll()
    }
}
