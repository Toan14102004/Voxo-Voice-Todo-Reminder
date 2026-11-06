//
//  Public+UI+CameraZoomLevelsDemo.swift
//  Pose
//
//  Created by Toan Nguyen on 24/8/25.
//

import AVFoundation
import SwiftUI

// MARK: - Camera Zoom Levels Demo View

public struct CameraZoomLevelsDemoView: View {
    @StateObject private var cameraManager = CameraManager(
        captureSession: AVCaptureSession(),
        captureDeviceInputType: AVCaptureDeviceInput.self
    )

    public init() {}

    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Device Information
                if !cameraManager.publicDeviceInformation.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Device Information")
                            .font(.headline)

                        ScrollView {
                            Text(cameraManager.publicDeviceInformation)
                                .font(.caption)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 200)
                    }
                }

                // Loading State
                if cameraManager.publicIsZoomManagerLoading {
                    HStack {
                        ProgressView()
                        Text("Loading zoom levels...")
                    }
                }

                // Error State
                if let errorMessage = cameraManager.publicZoomManagerErrorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }

                // Zoom Levels List
                if !cameraManager.publicAvailableZoomLevels.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available Zoom Levels")
                            .font(.headline)

                        LazyVStack(spacing: 8) {
                            ForEach(cameraManager.publicAvailableZoomLevels) { zoomLevel in
                                ZoomLevelRowView(zoomLevel: zoomLevel)
                            }
                        }
                    }
                }

                Spacer()

                // Refresh Button
                Button("Refresh Zoom Levels") {
                    Task {
                        await cameraManager.publicRefreshZoomLevels()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Camera Zoom Levels")
        }
    }
}

// MARK: - Zoom Level Row View

private struct ZoomLevelRowView: View {
    let zoomLevel: CameraZoomLevel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(zoomLevel.displayName)
                    .font(.headline)

                Text(zoomLevel.cameraType)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    if zoomLevel.publicIsUltraWide {
                        Label("Ultra Wide", systemImage: "camera.wide.angle")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }

                    if zoomLevel.publicIsWide {
                        Label("Wide", systemImage: "camera")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }

                    if zoomLevel.publicIsTelephoto {
                        Label("Telephoto", systemImage: "camera.telephoto")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            Text("\(zoomLevel.factor, specifier: "%.1f")x")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    CameraZoomLevelsDemoView()
}
