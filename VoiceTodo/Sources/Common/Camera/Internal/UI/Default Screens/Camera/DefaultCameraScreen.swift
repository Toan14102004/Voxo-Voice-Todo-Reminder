//
//  DefaultCameraScreen.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import SwiftUI

public struct DefaultCameraScreen: MCameraScreen {
    @ObservedObject public var cameraManager: CameraManager
    public let namespace: Namespace.ID
    public let closeMCameraAction: () -> Void

    public var body: some View {
        ZStack {
            createContentView()
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Asset.Color.black.color.ignoresSafeArea())
        .statusBarHidden()
        .animation(.mSpring)
    }
}

private extension DefaultCameraScreen {
    func createContentView() -> some View {
        createCameraOutputView()
            .ignoresSafeArea()
    }
}

extension DefaultCameraScreen {
    var iconAngle: Angle { switch isOrientationLocked {
    case true: deviceOrientation.getAngle()
    case false: .zero
    }}
}
