//
//  Public+Model+CameraUtilities.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import SwiftUI

// MARK: Camera Output Type

public enum CameraOutputType: CaseIterable {
    case photo
    case video
}

// MARK: Camera Position

public enum CameraPosition: CaseIterable {
    case back
    case front
}

// MARK: Camera Flash Mode

public enum CameraFlashMode: CaseIterable {
    case off
    case on
    case auto
}

// MARK: Camera Light Mode

public enum CameraLightMode: CaseIterable {
    case off
    case on
}

// MARK: Camera HDR Mode

public enum CameraHDRMode: CaseIterable {
    case off
    case on
    case auto
}

// MARK: Grid

public enum Grid: CaseIterable {
    case off
    case threeByThree
    case fourByFour
}

// MARK: ImageAspectRatio

public enum ImageAspectRatio: CaseIterable {
    case oneOne
    case fourThree
    case sixteenNine
    case full
}

// MARK: CaptureDelay

public enum CaptureDelay: CaseIterable {
    case three
    case six
    case nine
    case off
}

// MARK: Sound

public enum Sound: CaseIterable {
    case on
    case off
}

// MARK: Focus

public enum Focus: CaseIterable {
    case auto
    case manual
}

// MARK: Mirror

public enum MirrorType: CaseIterable {
    case on
    case off
}

// MARK: Vibrate

public enum Vibrate: CaseIterable {
    case on
    case off
}
