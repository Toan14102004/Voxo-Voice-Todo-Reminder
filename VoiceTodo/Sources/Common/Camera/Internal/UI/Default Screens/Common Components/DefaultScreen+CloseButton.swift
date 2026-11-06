//
//  DefaultScreen+CloseButton.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import SwiftUI

struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action, label: createButtonLabel)
    }
}

private extension CloseButton {
    func createButtonLabel() -> some View {
        Asset.Icon.Commo.arrowLeft.image
            .resizable()
            .frame(width: 24, height: 24)
            .foregroundColor(Asset.Color.gray.color)
    }
}
