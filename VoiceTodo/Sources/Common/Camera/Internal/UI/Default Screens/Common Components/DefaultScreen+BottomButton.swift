//
//  DefaultScreen+BottomButton.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import SwiftUI

struct BottomButton: View {
    let icon: UIImage
    let iconColor: Color
    let backgroundColor: Color
    let rotationAngle: Angle
    let action: () -> Void

    var body: some View {
        Button(action: action, label: createButtonLabel)
    }
}

private extension BottomButton {
    func createButtonLabel() -> some View {
        Image(uiImage: icon)
            .resizable()
            .frame(width: 26, height: 26)
            .foregroundColor(iconColor)
            .rotationEffect(rotationAngle)
            .frame(width: 52, height: 52)
            .background(backgroundColor)
            .mask(Circle())
    }
}
