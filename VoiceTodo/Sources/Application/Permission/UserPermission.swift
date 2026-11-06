//
//  UserPermission.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 13/2/25.
//

import Combine
import CoreLocation
import Foundation
import Photos
import UserNotifications

enum Permission: Hashable {
    case pushNotifications
    case photoLibrary(accessLevel: PHAccessLevel)
    case camera
    case microphone
    case location
}

extension Permission {
    enum Status: Equatable {
        case unknown
        case notRequested
        case granted
        case denied
    }
}

protocol UserPermissionsInteractor: AnyObject {
    func resolveStatus(for permission: Permission) // Check status of permission
    func request(permission: Permission)
        -> AnyPublisher<Permission.Status, Never> // Request permission and return status
    func getStatus(for permission: Permission) -> Permission.Status // Get current status
    func statusPublisher(for permission: Permission)
        -> AnyPublisher<Permission.Status, Never> // Publisher for permission status changes
}

final class RealUserPermissionsInteractor: UserPermissionsInteractor, Service {
    // MARK: - Published Properties

    @Published var permissionStatuses: [Permission: Permission.Status] = [:]

    // MARK: - Private Properties

    private let notificationCenter: SystemNotificationsCenter
    private let photoLibraryCenter: SystemPhotoLibraryCenter
    private let openAppSettings: () -> Void
    private let cancelBag = CancelBag()

    // MARK: - Service Protocol

    var shouldAutostart: Bool { true }

    init(
        notificationCenter: SystemNotificationsCenter = UNUserNotificationCenter.current(),
        photoLibraryCenter: SystemPhotoLibraryCenter = PHPhotoLibrary.shared(),
        openAppSettings: @escaping () -> Void
    ) {
        self.notificationCenter = notificationCenter
        self.photoLibraryCenter = photoLibraryCenter
        self.openAppSettings = openAppSettings
    }

    func start() {
        // Initialize permission statuses
        resolveStatus(for: .pushNotifications)
        resolveStatus(for: .photoLibrary(accessLevel: .readWrite))
        resolveStatus(for: .camera)
        resolveStatus(for: .location)
    }

    func stop() {
        // No cleanup needed for permissions
    }

    func getStatus(for permission: Permission) -> Permission.Status {
        permissionStatuses[permission] ?? .unknown
    }

    func statusPublisher(for permission: Permission) -> AnyPublisher<Permission.Status, Never> {
        $permissionStatuses
            .map { $0[permission] ?? .unknown }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func resolveStatus(for permission: Permission) {
        switch permission {
        case .pushNotifications:
            Task { @MainActor in
                let status = await pushNotificationsPermissionStatus()
                permissionStatuses[permission] = status
                print("Notification: \(status)")
            }
        case let .photoLibrary(accessLevel):
            Task { @MainActor in
                let status = await photosPermissionStatus(for: accessLevel)
                permissionStatuses[permission] = status
                print("Photo: \(status)")
            }
        case .camera:
            Task { @MainActor in
                let status = await cameraPermissionStatus()
                permissionStatuses[permission] = status
                print("Camera: \(status)")
            }
        case .microphone:
            Task { @MainActor in
                let status = await microphonePermissionStatus()
                permissionStatuses[permission] = status
                print("Microphone: \(status)")
            }
        case .location:
            Task { @MainActor in
                let status = await locationPermissionStatus()
                permissionStatuses[permission] = status
                print("Location: \(status)")
            }
        }
    }

    func request(permission: Permission) -> AnyPublisher<Permission.Status, Never> {
        let currentStatus = permissionStatuses[permission] ?? .unknown

        // If already denied, open settings and return current status
        guard currentStatus != Permission.Status.denied else {
//            openAppSettings()
            return Just(currentStatus).eraseToAnyPublisher()
        }

        // If already granted, return current status immediately
        guard currentStatus != Permission.Status.granted else {
            return Just(currentStatus).eraseToAnyPublisher()
        }

        // Request permission and return publisher that emits the result
        return Future<Permission.Status, Never> { [weak self] promise in
            guard let self else {
                promise(.success(.unknown))
                return
            }

            Task {
                let newStatus: Permission.Status

                switch permission {
                case .pushNotifications:
                    await self.requestPushNotificationsPermission()
                    newStatus = self.permissionStatuses[permission] ?? .unknown
                case let .photoLibrary(accessLevel):
                    await self.requestPhotoLibraryPermission(for: accessLevel)
                    newStatus = self.permissionStatuses[permission] ?? .unknown
                case .camera:
                    await self.requestCameraPermission()
                    newStatus = self.permissionStatuses[permission] ?? .unknown
                case .microphone:
                    await self.requestMicrophonePermission()
                    newStatus = self.permissionStatuses[permission] ?? .unknown
                case .location:
                    await self.requestLocationPermission()
                    newStatus = self.permissionStatuses[permission] ?? .unknown
                }

                await MainActor.run {
                    promise(.success(newStatus))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Notification

private extension RealUserPermissionsInteractor {
    func pushNotificationsPermissionStatus() async -> Permission.Status {
        await notificationCenter
            .currentSettings()
            .authorizationStatus.map
    }

    func requestPushNotificationsPermission() async {
        let center = notificationCenter
        let isGranted = await (try? center.requestAuthorization(options: [.alert, .sound])) ?? false
        await MainActor.run {
            permissionStatuses[.pushNotifications] = isGranted ? .granted : .denied
        }
    }
}

// MARK: - Photos

private extension RealUserPermissionsInteractor {
    func photosPermissionStatus(for accessLevel: PHAccessLevel) async -> Permission.Status {
        let status = PHPhotoLibrary.authorizationStatus(for: accessLevel)
        return status.map
    }

    func requestPhotoLibraryPermission(for accessLevel: PHAccessLevel) async {
        let center = photoLibraryCenter
        let status = await (try? center.requestAuthorization(for: accessLevel)) ?? .denied
        await MainActor.run {
            permissionStatuses[.photoLibrary(accessLevel: accessLevel)] = status
        }
    }
}
