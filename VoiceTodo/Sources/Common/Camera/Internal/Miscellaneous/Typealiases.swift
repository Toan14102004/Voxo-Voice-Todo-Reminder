//
//  Typealiases.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import SwiftUI

public typealias CameraScreenBuilder = @MainActor (
    CameraManager,
    Namespace.ID,
    _ closeMCameraAction: @escaping () -> Void
) -> any MCameraScreen
public typealias CapturedMediaScreenBuilder = @MainActor (
    MCameraMedia,
    Namespace.ID,
    _ retakeAction: @escaping () -> Void,
    _ acceptMediaAction: @escaping () -> Void
) -> any MCapturedMediaScreen
public typealias ErrorScreenBuilder = @MainActor (MCameraError, _ closeMCameraAction: @escaping () -> Void)
    -> any MCameraErrorScreen
