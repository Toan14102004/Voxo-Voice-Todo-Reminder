//
//  CropImageView.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 11/9/25.
//

import Mantis
import SwiftUI

enum CropAction {
    case crop
    case counterclockwiseRotate
    case clockwiseRotate
    case horizontallyFlip
    case verticallyFlip
    case reset
}

enum CropStatus {
    case succeeded(UIImage)
    case failed
}

struct ImageCropperView: UIViewControllerRepresentable {
    let config: Mantis.Config

    let image: UIImage?
    @Binding var transformation: Transformation?
    @Binding var cropInfo: CropInfo?
    @Binding var action: CropAction?
    @Binding var ratio: Double?
    @Binding var rotation: Double
    @Binding var scale: Double

    let onDismiss: () -> Void
    let onCropCompleted: (_ status: CropStatus) -> Void

    /// Creates an `ImageCropper` view with optional custom configuration and required image bindings.
    init(
        config: Mantis.Config = Mantis.Config(),
        image: UIImage?,
        transformation: Binding<Transformation?>,
        cropInfo: Binding<CropInfo?>,
        ratio: Binding<Double?> = .constant(nil),
        rotation: Binding<Double> = .constant(0),
        scale: Binding<Double> = .constant(1),
        action: Binding<CropAction?> = .constant(nil),
        onDismiss: @escaping () -> Void = {},
        onCropCompleted: @escaping (_ status: CropStatus) -> Void = { _ in }
    ) {
        self.config = config
        self.image = image
        _transformation = transformation
        _cropInfo = cropInfo
        _ratio = ratio
        _rotation = rotation
        _scale = scale
        _action = action
        self.onDismiss = onDismiss
        self.onCropCompleted = onCropCompleted
    }

    class Coordinator: CropViewControllerDelegate {
        var parent: ImageCropperView
        var cropViewController: Mantis.CropViewController?

        var actionBinding: Binding<CropAction?>
        var ratioBinding: Binding<Double?>
        var rotationBinding: Binding<Double>
        var scaleBinding: Binding<Double>

        private var isProcessingAction = false
        private var lastProcessedAction: CropAction?
        private var lastProcessedRatio: Double?
        private var lastProcessedRotation: Double?
        private var lastProcessedScale: Double?

        init(_ parent: ImageCropperView) {
            self.parent = parent
            actionBinding = parent._action
            ratioBinding = parent._ratio
            rotationBinding = parent._rotation
            scaleBinding = parent._scale
        }

        func cropViewControllerDidCrop(
            _: Mantis.CropViewController,
            cropped: UIImage,
            transformation: Transformation,
            cropInfo: CropInfo
        ) {
            isProcessingAction = true

            DispatchQueue.main.async {
                self.parent.transformation = transformation
                self.parent.cropInfo = cropInfo
                self.isProcessingAction = false
                self.parent.onDismiss()
                self.parent.onCropCompleted(.succeeded(cropped))
            }
        }

        func cropViewControllerDidCancel(_: Mantis.CropViewController, original _: UIImage) {
            DispatchQueue.main.async {
                self.parent.onDismiss()
            }
        }

        func cropViewControllerDidFailToCrop(_: Mantis.CropViewController, original _: UIImage) {
            DispatchQueue.main.async {
                self.isProcessingAction = false
                self.lastProcessedAction = nil
                self.parent.onDismiss()
                self.parent.onCropCompleted(.failed)
            }
        }

        func cropViewControllerDidBeginResize(_: Mantis.CropViewController) {}

        func cropViewControllerDidEndResize(
            _: Mantis.CropViewController,
            original _: UIImage,
            cropInfo _: Mantis.CropInfo
        ) {}

        func handleAction() {
            guard !isProcessingAction else { return }

            guard let cropVC = cropViewController else { return }

            guard let currentAction = actionBinding.wrappedValue else { return }

            if let lastAction = lastProcessedAction, areActionsEqual(lastAction, currentAction) {
                return
            }

            isProcessingAction = true
            lastProcessedAction = currentAction

            switch currentAction {
            case .crop:
                cropVC.crop()
                DispatchQueue.main.async {
                    self.isProcessingAction = false
                    self.lastProcessedAction = .crop
                }
            case .counterclockwiseRotate:
                cropVC.didSelectCounterClockwiseRotate()
                DispatchQueue.main.async {
                    self.isProcessingAction = false
                    self.lastProcessedAction = nil
                }
            case .clockwiseRotate:
                cropVC.didSelectClockwiseRotate()
                DispatchQueue.main.async {
                    self.isProcessingAction = false
                    self.lastProcessedAction = nil
                }
            case .horizontallyFlip:
                cropVC.didSelectHorizontallyFlip()
                DispatchQueue.main.async {
                    self.isProcessingAction = false
                    self.lastProcessedAction = nil
                }
            case .verticallyFlip:
                cropVC.didSelectVerticallyFlip()
                DispatchQueue.main.async {
                    self.isProcessingAction = false
                    self.lastProcessedAction = nil
                }
            case .reset:
                cropVC.didSelectReset()
                DispatchQueue.main.async {
                    self.isProcessingAction = false
                    self.lastProcessedAction = .reset
                }
            default:
                DispatchQueue.main.async {
                    self.isProcessingAction = false
                    self.lastProcessedAction = nil
                }
            }

            DispatchQueue.main.async {
                self.actionBinding.wrappedValue = nil
            }
        }
        
        func handleRatio() {
            guard let cropVC = cropViewController else { return }
            let currentRatio = ratioBinding.wrappedValue
            
            if lastProcessedRatio == currentRatio {
                return
            }
            
            lastProcessedRatio = currentRatio
            
            if let ratio = currentRatio {
                cropVC.didSelectReset()
                cropVC.didSelectRatio(ratio: ratio)
                
                // Re-apply current rotation and scale if they were set
                handleRotation()
                handleScale()
            } else {
                cropVC.didSelectReset()
            }
        }
        
        func handleRotation() {
            guard let cropVC = cropViewController else { return }
            let currentRotation = rotationBinding.wrappedValue
            
            if lastProcessedRotation == currentRotation {
                return
            }
            
            lastProcessedRotation = currentRotation
    
            let radians = currentRotation * .pi / 180.0
        
            let mirror = Mirror(reflecting: cropVC)
            for child in mirror.children {
                if let view = child.value as? UIView, String(describing: type(of: view)).contains("CropView") {
                    let selector = NSSelectorFromString("setRotationAngleWithRadians:")
                    if view.responds(to: selector) {
                        view.perform(selector, with: radians)
                        return
                    }
                }
            }
        }
        
        func handleScale() {
            guard let cropVC = cropViewController else { return }
            let currentScale = scaleBinding.wrappedValue
            
            if lastProcessedScale == currentScale {
                return
            }
            
            lastProcessedScale = currentScale
            
            let mirror = Mirror(reflecting: cropVC)
            for child in mirror.children {
                if let view = child.value as? UIView, String(describing: type(of: view)).contains("CropView") {
                    let subMirror = Mirror(reflecting: view)
                    for subChild in subMirror.children {
                        if let scrollView = subChild.value as? UIScrollView {
                            scrollView.setZoomScale(CGFloat(currentScale), animated: false)
                            return
                        }
                    }
                }
            }
        }

        private func areActionsEqual(_ lhs: CropAction, _ rhs: CropAction) -> Bool {
            switch (lhs, rhs) {
            case (.crop, .crop):
                true
            case (.counterclockwiseRotate, .counterclockwiseRotate):
                true
            case (.clockwiseRotate, .clockwiseRotate):
                true
            case (.horizontallyFlip, .horizontallyFlip):
                true
            case (.verticallyFlip, .verticallyFlip):
                true
            case (.reset, .reset):
                true
            default:
                false
            }
        }

        func updateParent(_ newParent: ImageCropperView) {
            parent = newParent
            actionBinding = newParent._action
            ratioBinding = newParent._ratio
            rotationBinding = newParent._rotation
            scaleBinding = newParent._scale
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        guard let imageToEdit = image else {
            // Return an appropriate fallback view controller or handle the nil case
            let emptyVC = UIViewController()
            // Optionally add a label explaining the error
            let label = UILabel()
            label.text = "No image provided for cropping"
            label.textAlignment = .center
            emptyVC.view.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: emptyVC.view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: emptyVC.view.centerYAnchor)
            ])
            return emptyVC
        }

        let cropViewController = Mantis.cropViewController(
            image: imageToEdit,
            config: config,
            cropToolbar: CropToolbar()
        )
        cropViewController.delegate = context.coordinator
        context.coordinator.cropViewController = cropViewController

        return cropViewController
    }

    func updateUIViewController(_: UIViewController, context: Context) {
        context.coordinator.updateParent(self)
        context.coordinator.handleAction()
        context.coordinator.handleRatio()
        context.coordinator.handleRotation()
        context.coordinator.handleScale()
    }
}
