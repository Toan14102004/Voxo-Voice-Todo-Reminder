//
//  CameraView+Metal.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import AVKit
import MetalKit
import SwiftUI

@MainActor class CameraMetalView: MTKView {
    private(set) var parent: CameraManager!
    private(set) var ciContext: CIContext!
    private(set) var commandQueue: MTLCommandQueue!
    private(set) var currentFrame: CIImage?
    private(set) var focusIndicator: CameraFocusIndicatorView = .init()
    private(set) var isAnimating: Bool = false
}

// MARK: Setup

extension CameraMetalView {
    func setup(parent: CameraManager) throws(MCameraError) {
        guard let metalDevice = MTLCreateSystemDefaultDevice() else { throw .cannotSetupMetalDevice }

        assignInitialValues(parent: parent, metalDevice: metalDevice)
        configureMetalView(metalDevice: metalDevice)
        addToParent(parent.cameraView)
    }
}

private extension CameraMetalView {
    func assignInitialValues(parent: CameraManager, metalDevice: MTLDevice) {
        self.parent = parent
        ciContext = CIContext(mtlDevice: metalDevice)
        commandQueue = metalDevice.makeCommandQueue()
    }

    func configureMetalView(metalDevice: MTLDevice) {
        parent.cameraView.alpha = 0

        delegate = self
        device = metalDevice
        isPaused = true
        enableSetNeedsDisplay = false
        framebufferOnly = false
        autoResizeDrawable = false
        contentMode = .scaleAspectFill
        clipsToBounds = true
    }
}

// MARK: - ANIMATIONS

// MARK: Camera Entrance

extension CameraMetalView {
    func performCameraEntranceAnimation() { UIView.animate(withDuration: 0.33) { [self] in
        parent.cameraView.alpha = 1
    }}
}

// MARK: Image Capture

extension CameraMetalView {
    func performImageCaptureAnimation() {
        let blackMatte = createBlackMatte()

        parent.cameraView.addSubview(blackMatte)
        animateBlackMatte(blackMatte)
    }
}

private extension CameraMetalView {
    func createBlackMatte() -> UIView {
        let view = UIView()
        view.frame = parent.cameraView.frame
        view.backgroundColor = Asset.Color.black.uiColor
        view.alpha = 0
        return view
    }

    func animateBlackMatte(_ view: UIView) {
        UIView.animate(withDuration: 0.16, animations: { view.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.16, animations: { view.alpha = 0 }) { _ in
                view.removeFromSuperview()
            }
        }
    }
}

// MARK: Camera Flip

extension CameraMetalView {
    func beginCameraFlipAnimation() async {
        let snapshot = createSnapshot()
        isAnimating = true
        insertBlurView(snapshot)
        animateBlurFlip()

        await Task.sleep(seconds: 0.01)
    }

    func finishCameraFlipAnimation() async {
        guard let blurView = parent.cameraView.viewWithTag(.blurViewTag) else { return }

        await Task.sleep(seconds: 0.44)
        UIView.animate(withDuration: 0.3, animations: { blurView.alpha = 0 }) { [self] _ in
            blurView.removeFromSuperview()
            isAnimating = false
        }
    }
}

private extension CameraMetalView {
    func createSnapshot() -> UIImage? {
        guard let currentFrame else { return nil }

        let image = UIImage(ciImage: currentFrame)
        return image
    }

    func insertBlurView(_ snapshot: UIImage?) {
        let blurView = UIImageView(frame: parent.cameraView.frame)
        blurView.image = snapshot
        blurView.contentMode = .scaleAspectFill
        blurView.clipsToBounds = true
        blurView.tag = .blurViewTag
        blurView.applyBlurEffect(style: .regular)

        parent.cameraView.addSubview(blurView)
    }

    func animateBlurFlip() {
        UIView.transition(with: parent.cameraView, duration: 0.44, options: cameraFlipAnimationTransition) {}
    }
}

private extension CameraMetalView {
    var cameraFlipAnimationTransition: UIView
        .AnimationOptions {
        parent.attributes.cameraPosition == .back ? .transitionFlipFromLeft : .transitionFlipFromRight
    }
}

// MARK: Camera Focus

extension CameraMetalView {
    func performCameraFocusAnimation(touchPoint: CGPoint) {
        removeExistingFocusIndicatorAnimations()

        let focusIndicator = focusIndicator.create(at: touchPoint)
        parent.cameraView.addSubview(focusIndicator)
        animateFocusIndicator(focusIndicator)
    }
}

private extension CameraMetalView {
    func removeExistingFocusIndicatorAnimations() { if let view = parent.cameraView.viewWithTag(.focusIndicatorTag) {
        view.removeFromSuperview()
    }}
    func animateFocusIndicator(_ focusIndicator: UIImageView) {
        UIView.animate(
            withDuration: 0.44,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0,
            animations: { focusIndicator.transform = .init(scaleX: 1, y: 1) }
        ) { _ in
            UIView.animate(withDuration: 0.44, delay: 1.44, animations: { focusIndicator.alpha = 0.2 }) { _ in
                UIView.animate(withDuration: 0.44, delay: 1.44, animations: { focusIndicator.alpha = 0 })
            }
        }
    }
}

// MARK: Camera Orientation

extension CameraMetalView {
    func beginCameraOrientationAnimation(if shouldAnimate: Bool) async { if shouldAnimate {
        parent.cameraView.alpha = 0
        await Task.sleep(seconds: 0.1)
    }}
    func finishCameraOrientationAnimation(if shouldAnimate: Bool) { if shouldAnimate {
        UIView.animate(withDuration: 0.2, delay: 0.1) { self.parent.cameraView.alpha = 1 }
    }}
}

// MARK: - CAPTURING FRAMES

// MARK: Capture
extension CameraMetalView: @preconcurrency AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
        guard let cvImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Fetch attributes securely from Main Thread
        var orientation: CGImagePropertyOrientation = .right
        var filters: [CIFilter] = []
        
        DispatchQueue.main.sync {
            orientation = parent.attributes.frameOrientation
            filters = parent.attributes.cameraFilters
        }

        // Heavy processing on Background Thread
        let currentFrame = captureCurrentFrame(cvImageBuffer, orientation: orientation)
        let currentFrameWithFiltersApplied = applyingFiltersToCurrentFrame(currentFrame, filters: filters)
        
        // Update UI on Main Thread
        Task { @MainActor in
            redrawCameraView(currentFrameWithFiltersApplied)
        }
    }
}

private extension CameraMetalView {
    nonisolated func captureCurrentFrame(_ cvImageBuffer: CVImageBuffer, orientation: CGImagePropertyOrientation) -> CIImage {
        let currentFrame = CIImage(cvImageBuffer: cvImageBuffer)
        return currentFrame.oriented(orientation)
    }

    nonisolated func applyingFiltersToCurrentFrame(_ currentFrame: CIImage, filters: [CIFilter]) -> CIImage {
        currentFrame.applyingFilters(filters)
    }

    func redrawCameraView(_ frame: CIImage) {
        currentFrame = frame
        draw()
    }
}

// MARK: Draw

extension CameraMetalView: MTKViewDelegate {
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let ciImage = currentFrame,
              let currentDrawable = view.currentDrawable
        else { return }

        changeDrawableSize(view, ciImage)
        renderView(view, currentDrawable, commandBuffer, ciImage)
        commitBuffer(currentDrawable, commandBuffer)
    }

    func mtkView(_: MTKView, drawableSizeWillChange _: CGSize) {}
}

private extension CameraMetalView {
    func changeDrawableSize(_ view: MTKView, _ ciImage: CIImage) {
        view.drawableSize = ciImage.extent.size
    }

    func renderView(
        _ view: MTKView,
        _ currentDrawable: any CAMetalDrawable,
        _ commandBuffer: any MTLCommandBuffer,
        _ ciImage: CIImage
    ) { ciContext.render(
        ciImage,
        to: currentDrawable.texture,
        commandBuffer: commandBuffer,
        bounds: .init(origin: .zero, size: view.drawableSize),
        colorSpace: CGColorSpaceCreateDeviceRGB()
    ) }
    func commitBuffer(_ currentDrawable: any CAMetalDrawable, _ commandBuffer: any MTLCommandBuffer) {
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
}
