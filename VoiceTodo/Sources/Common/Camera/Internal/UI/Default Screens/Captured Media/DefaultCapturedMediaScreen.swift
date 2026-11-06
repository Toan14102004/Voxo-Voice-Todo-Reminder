//
//  DefaultCapturedMediaScreen.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import AVKit
import SwiftUI

struct DefaultCapturedMediaScreen: MCapturedMediaScreen {
    let capturedMedia: MCameraMedia
    let namespace: Namespace.ID
    let retakeAction: () -> Void
    let acceptMediaAction: () -> Void
    @State private var player: AVPlayer = .init()
    @State private var isInitialized: Bool = false

    var body: some View {
        ZStack {
            createContentView()
            createButtons()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Asset.Color.black.color.ignoresSafeArea())
        .animation(.mSpring, value: isInitialized)
        .onAppear { isInitialized = true }
    }
}

private extension DefaultCapturedMediaScreen {
    @ViewBuilder func createContentView() -> some View { if isInitialized {
        if let image = capturedMedia.getImage() { createImageView(image) }
        else if let video = capturedMedia.getVideo() { createVideoView(video) }
    }}
    func createButtons() -> some View {
        HStack(spacing: 32) {
            createRetakeButton()
            createSaveButton()
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 8)
    }
}

private extension DefaultCapturedMediaScreen {
    func createImageView(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .ignoresSafeArea()
            .transition(.scale(scale: 1.1))
    }

    func createVideoView(_ video: URL) -> some View {
        VideoPlayer(player: player)
            .onAppear { onVideoAppear(video) }
    }

    @ViewBuilder func createRetakeButton() -> some View { if isInitialized {
        BottomButton(
            icon: Asset.Icon.Commo.arrowLeft.uiImage,
            iconColor: Asset.Color.gray.color,
            backgroundColor: Asset.Color.black.color,
            rotationAngle: .zero,
            action: retakeAction
        )
        .transition(.scale)
    }}
    @ViewBuilder func createSaveButton() -> some View { if isInitialized {
        BottomButton(
            icon: Asset.Icon.Commo.checkmark.uiImage,
            iconColor: Asset.Color.primary.color,
            backgroundColor: Asset.Color.black.color,
            rotationAngle: .zero,
            action: acceptMediaAction
        )
        .transition(.scale)
    }}
}

private extension DefaultCapturedMediaScreen {
    func onVideoAppear(_ url: URL) {
        player = .init(url: url)
        player.play()
    }
}
