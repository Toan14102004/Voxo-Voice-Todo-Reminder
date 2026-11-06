//
//  CameraZoomManager.swift
//  Pose
//
//  Created by Toan Nguyen on 24/8/25.
//

import AVFoundation
import Foundation

@MainActor
class CameraZoomManager: ObservableObject {
    @Published var zoomLevels: [CameraZoomLevel] = []
    @Published var deviceInfo: String = ""
    @Published var isLoading = true
    @Published var errorMessage: String?

    init() {
        Task {
            await loadZoomLevels()
        }
    }

    func loadZoomLevels() async {
        do {
            let status = AVCaptureDevice.authorizationStatus(for: .video)

            if status == .notDetermined {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if !granted {
                    errorMessage = "Cần cấp quyền camera để hiển thị thông tin"
                    isLoading = false
                    return
                }
            } else if status != .authorized {
                errorMessage = "Quyền camera bị từ chối"
                isLoading = false
                return
            }

            await detectZoomLevels()
            isLoading = false
        }
    }

    private func detectZoomLevels() async {
        var detectedLevels: [CameraZoomLevel] = []

        // Device types to check
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInTripleCamera,
            .builtInDualWideCamera,
            .builtInDualCamera,
            .builtInWideAngleCamera,
            .builtInUltraWideCamera,
            .builtInTelephotoCamera
        ]

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .back
        )

        var deviceInfoString = ""

        for device in discoverySession.devices {
            deviceInfoString += "📱 \(device.localizedName)\n"
            deviceInfoString += "📋 Type: \(getDeviceTypeName(device.deviceType))\n"

            // Check if it's a multi-camera device
            if !device.constituentDevices.isEmpty {
                deviceInfoString += "📷 Multi-camera system:\n"

                for constituent in device.constituentDevices {
                    let zoomFactor = getZoomFactorForDevice(constituent.deviceType)
                    let cameraName = getCameraName(constituent.deviceType)

                    if zoomFactor > 0 {
                        let zoomLevel = CameraZoomLevel(
                            factor: zoomFactor,
                            cameraType: cameraName,
                            deviceType: constituent.deviceType
                        )

                        if !detectedLevels.contains(where: { $0.factor == zoomLevel.factor }) {
                            detectedLevels.append(zoomLevel)
                        }
                    }

                    deviceInfoString += "  • \(cameraName): \(zoomFactor)x\n"
                    deviceInfoString += "    Min: \(constituent.minAvailableVideoZoomFactor)\n"
                    deviceInfoString += "    Max: \(constituent.maxAvailableVideoZoomFactor)\n"
                }
            } else {
                // Single camera device
                let zoomFactor = getZoomFactorForDevice(device.deviceType)
                let cameraName = getCameraName(device.deviceType)

                if zoomFactor > 0 {
                    let zoomLevel = CameraZoomLevel(
                        factor: zoomFactor,
                        cameraType: cameraName,
                        deviceType: device.deviceType
                    )

                    if !detectedLevels.contains(where: { $0.factor == zoomLevel.factor }) {
                        detectedLevels.append(zoomLevel)
                    }
                }

                deviceInfoString += "📷 Single camera: \(cameraName) (\(zoomFactor)x)\n"
            }

            deviceInfoString += "🔍 Zoom range: \(device.minAvailableVideoZoomFactor) - \(device.maxAvailableVideoZoomFactor)\n\n"
        }

        zoomLevels = detectedLevels.sorted { $0.factor < $1.factor }
        deviceInfo = deviceInfoString
    }

    private func getZoomFactorForDevice(_ deviceType: AVCaptureDevice.DeviceType) -> Double {
        switch deviceType {
        case .builtInUltraWideCamera:
            0.5
        case .builtInWideAngleCamera:
            1.0
        case .builtInTelephotoCamera:
            // Different devices have different telephoto zoom
            getTelephotoZoomFactor()
        default:
            1.0
        }
    }

    private func getTelephotoZoomFactor() -> Double {
        let deviceModel = getDeviceModel()

        // iPhone specific zoom factors
        if deviceModel.contains("iPhone13,2") || deviceModel.contains("iPhone13,3") { // iPhone 12 Pro/Pro Max
            return 2.5
        } else if deviceModel.contains("iPhone14,2") || deviceModel.contains("iPhone14,3") { // iPhone 13 Pro/Pro Max
            return 3.0
        } else if deviceModel.contains("iPhone15,2") || deviceModel.contains("iPhone15,3") { // iPhone 14 Pro/Pro Max
            return 3.0
        } else {
            return 2.0 // Default for older models like iPhone 11 Pro
        }
    }

    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
    }

    private func getCameraName(_ deviceType: AVCaptureDevice.DeviceType) -> String {
        switch deviceType {
        case .builtInUltraWideCamera:
            "Ultra Wide"
        case .builtInWideAngleCamera:
            "Wide"
        case .builtInTelephotoCamera:
            "Telephoto"
        case .builtInTripleCamera:
            "Triple Camera"
        case .builtInDualWideCamera:
            "Dual Wide Camera"
        case .builtInDualCamera:
            "Dual Camera"
        default:
            "Unknown Camera"
        }
    }

    private func getDeviceTypeName(_ deviceType: AVCaptureDevice.DeviceType) -> String {
        switch deviceType {
        case .builtInTripleCamera:
            "Triple Camera System"
        case .builtInDualWideCamera:
            "Dual Wide Camera System"
        case .builtInDualCamera:
            "Dual Camera System"
        case .builtInWideAngleCamera:
            "Wide Angle Camera"
        case .builtInUltraWideCamera:
            "Ultra Wide Camera"
        case .builtInTelephotoCamera:
            "Telephoto Camera"
        default:
            "Unknown"
        }
    }
}

// MARK: - Public Interface

extension CameraZoomManager {
    /// Returns the available zoom levels for the current device
    var availableZoomLevels: [CameraZoomLevel] {
        zoomLevels
    }

    /// Returns the device information string
    var deviceInformation: String {
        deviceInfo
    }

    /// Returns true if the manager is currently loading zoom levels
    var isCurrentlyLoading: Bool {
        isLoading
    }

    /// Returns the current error message if any
    var currentErrorMessage: String? {
        errorMessage
    }

    /// Refreshes the zoom levels detection
    func refreshZoomLevels() async {
        isLoading = true
        errorMessage = nil
        await loadZoomLevels()
    }
}
