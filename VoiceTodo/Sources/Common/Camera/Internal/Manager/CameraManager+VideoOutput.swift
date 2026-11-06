//
//  CameraManager+VideoOutput.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

@preconcurrency import AVKit
import MijickTimer
import SwiftUI

@MainActor class CameraManagerVideoOutput: NSObject {
    private(set) var parent: CameraManager!
    private(set) var output: AVCaptureMovieFileOutput = .init()
    private(set) var timer: MTimer = .init(.camera)
    private(set) var recordingTime: MTime = .zero
    private(set) var firstRecordedFrame: UIImage?
}

// MARK: Setup

extension CameraManagerVideoOutput {
    func setup(parent: CameraManager) throws(MCameraError) {
        self.parent = parent
        try parent.captureSession.add(output: output)
    }
}

// MARK: Reset

extension CameraManagerVideoOutput {
    func reset() {
        timer.reset()
    }
}

// MARK: - CAPTURE VIDEO

// MARK: Toggle

extension CameraManagerVideoOutput {
    func toggleRecording() { switch output.isRecording {
    case true: stopRecording()
    case false: startRecording()
    }}
}

// MARK: Start Recording

private extension CameraManagerVideoOutput {
    func cropCGImageToCameraViewAspect(_ cgImage: CGImage) -> CGImage? {
        guard let parent = parent else {
            return cgImage
        }
        
        let viewSize = parent.cameraView?.bounds.size ?? .zero
        guard viewSize.width > 0, viewSize.height > 0 else { return cgImage }

        let targetAspect = viewSize.width / viewSize.height
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
    
    func startRecording() {
        guard let url = prepareUrlForVideoRecording() else { return }

        configureOutput()
        storeLastFrame()
        output.startRecording(to: url, recordingDelegate: self)
        startRecordingTimer()
        parent.objectWillChange.send()
    }
}

private extension CameraManagerVideoOutput {
    func prepareUrlForVideoRecording() -> URL? {
        FileManager.prepareURLForVideoOutput()
    }

    func configureOutput() {
        guard let connection = output.connection(with: .video), connection.isVideoMirroringSupported else { return }

        connection.isVideoMirrored = parent.attributes.mirrorOutput ? parent.attributes
            .cameraPosition != .front : parent.attributes.cameraPosition == .front
        connection.videoOrientation = parent.attributes.deviceOrientation
    }

    func storeLastFrame() {
        guard let texture = parent.cameraMetalView.currentDrawable?.texture,
              let ciImage = CIImage(mtlTexture: texture, options: nil),
              let originalCGImage = parent.cameraMetalView.ciContext.createCGImage(ciImage, from: ciImage.extent)
        else { return }

        let croppedCGImage = cropCGImageToCameraViewAspect(originalCGImage) ?? originalCGImage
        firstRecordedFrame = UIImage(cgImage: croppedCGImage,
                                     scale: 1.0,
                                     orientation: parent.attributes.deviceOrientation.toImageOrientation())
    }

    func startRecordingTimer() { try? timer
        .publish(every: 1) { [self] in
            recordingTime = $0
            parent.objectWillChange.send()
        }
        .start()
    }
}

// MARK: Stop Recording

private extension CameraManagerVideoOutput {
    func stopRecording() {
        parent.startLoading()
        output.stopRecording()
        timer.reset()
    }
}

private extension CameraManagerVideoOutput {
    func presentLastFrame() {
        let firstRecordedFrame = MCameraMedia(data: firstRecordedFrame)
        parent.setCapturedMedia(firstRecordedFrame)
    }
}

// MARK: Receive Data

extension CameraManagerVideoOutput: @preconcurrency AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from _: [AVCaptureConnection],
        error _: (any Error)?
    ) { Task {
        let videoURL = try await prepareVideo(
            outputFileURL: outputFileURL,
            cameraFilters: parent.attributes.cameraFilters
        )
        let capturedVideo = MCameraMedia(data: videoURL)

        parent.stopLoading()
        await Task.sleep(seconds: Animation.duration)
        parent.setCapturedMedia(capturedVideo)
    }}
}

private extension CameraManagerVideoOutput {
    func prepareVideo(outputFileURL: URL, cameraFilters: [CIFilter]) async throws -> URL {
        let asset = AVAsset(url: outputFileURL)
        // Build a composition cropped to match the aspect ratio of the preview (parent.cameraView)
        let viewBounds = parent.cameraView?.bounds ?? .zero
        let viewAspectRatio = viewBounds.height > 0 ? (viewBounds.width / viewBounds.height) : 1
        let cropSize = computeCropSize(for: asset, targetAspect: viewAspectRatio)

        let videoComposition = try await createCroppedComposition(
            asset: asset,
            filters: cameraFilters,
            cropSize: cropSize
        )
        let fileUrl = FileManager.prepareURLForVideoOutput()
        let exportSession = prepareAssetExportSession(asset, fileUrl, videoComposition)

        try await exportVideo(exportSession, fileUrl)
        return fileUrl ?? outputFileURL
    }
}

private extension CameraManagerVideoOutput {
    nonisolated func applyFiltersToVideo(_ request: AVAsynchronousCIImageFilteringRequest, _ filters: [CIFilter]) {
        let videoFrame = prepareVideoFrame(request, filters)
        request.finish(with: videoFrame, context: nil)
    }

    nonisolated func exportVideo(_ exportSession: AVAssetExportSession?, _ fileUrl: URL?) async throws {
        if let fileUrl {
            if #available(iOS 18, *) { try await exportSession?.export(to: fileUrl, as: .mov) }
            else { await exportSession?.export() }
        }
    }
}

private extension CameraManagerVideoOutput {
    func createCroppedComposition(
        asset: AVAsset,
        filters: [CIFilter],
        cropSize: CGSize
    ) async throws -> AVVideoComposition {
        // Use AVMutableVideoComposition to allow setting renderSize
        let composition = AVMutableVideoComposition(asset: asset, applyingCIFiltersWithHandler: { [weak self] request in
            self?.applyFiltersAndCenterCrop(request, filters, cropSize: cropSize)
        })
        composition.renderSize = cropSize
        return composition
    }

    nonisolated func applyFiltersAndCenterCrop(
        _ request: AVAsynchronousCIImageFilteringRequest,
        _ filters: [CIFilter],
        cropSize: CGSize
    ) {
        let baseImage: CIImage = {
            if filters.isEmpty { return request.sourceImage }
            return request.sourceImage
                .clampedToExtent()
                .applyingFilters(filters)
        }()

        // Compute center crop rect within the current frame extent
        let extent = baseImage.extent
        let cropW = min(cropSize.width, extent.width)
        let cropH = min(cropSize.height, extent.height)
        let originX = extent.origin.x + (extent.width - cropW) / 2.0
        let originY = extent.origin.y + (extent.height - cropH) / 2.0
        let cropRect = CGRect(x: originX, y: originY, width: cropW, height: cropH)

        // Crop and translate to the origin per Apple guidance
        guard let cropFilter = CIFilter(name: "CICrop") else {
            request.finish(with: baseImage, context: nil)
            return
        }
        cropFilter.setValue(baseImage, forKey: kCIInputImageKey)
        cropFilter.setValue(CIVector(cgRect: cropRect), forKey: "inputRectangle")

        if let cropped = cropFilter.outputImage?.transformed(by: CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y)) {
            request.finish(with: cropped, context: nil)
        } else {
            request.finish(with: baseImage, context: nil)
        }
    }
}

private extension CameraManagerVideoOutput {
    func computeCropSize(for asset: AVAsset, targetAspect: CGFloat) -> CGSize {
        guard let track = asset.tracks(withMediaType: .video).first else {
            // Fallback square size if track is unavailable
            let side: CGFloat = 1080
            return .init(width: side, height: side)
        }

        let natural = track.naturalSize
        let t = track.preferredTransform
        // Heuristic: portrait if the transform swaps width/height (common case)
        let isPortrait = (t.a == 0 && abs(t.b) == 1 && abs(t.c) == 1 && t.d == 0)
        let sourceWidth: CGFloat = isPortrait ? natural.height : natural.width
        let sourceHeight: CGFloat = isPortrait ? natural.width : natural.height

        let sourceAspect = sourceWidth / sourceHeight

        if targetAspect >= sourceAspect {
            // Wider target than source → limit by width
            let width = sourceWidth
            let height = max(1, width / max(targetAspect, 0.0001))
            return .init(width: width.rounded(.towardZero), height: height.rounded(.towardZero))
        } else {
            // Taller target than source → limit by height
            let height = sourceHeight
            let width = max(1, height * targetAspect)
            return .init(width: width.rounded(.towardZero), height: height.rounded(.towardZero))
        }
    }

    nonisolated func prepareVideoFrame(
        _ request: AVAsynchronousCIImageFilteringRequest,
        _ filters: [CIFilter]
    ) -> CIImage { request
        .sourceImage
        .clampedToExtent()
        .applyingFilters(filters)
    }

    nonisolated func prepareAssetExportSession(
        _ asset: AVAsset,
        _ fileUrl: URL?,
        _ composition: AVVideoComposition?
    ) -> AVAssetExportSession? {
        let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1920x1080)
        export?.outputFileType = .mov
        export?.outputURL = fileUrl
        export?.videoComposition = composition
        return export
    }
}

// MARK: - HELPERS

private extension MTimerID {
    static let camera: MTimerID = .init(rawValue: "mijick-camera")
}
