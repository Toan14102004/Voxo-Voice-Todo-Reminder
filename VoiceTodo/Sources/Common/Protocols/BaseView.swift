//
//  BaseView.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 11/2/25.
//

import SwiftUI

struct BaseView<Content: View>: View {
    @Environment(\.dismiss) var dismiss

    var background: Color
    let content: Content
    let onBackAction: (() -> Void)? = nil

    init(background: Color = Asset.Color.black.color, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.background = background
    }

    var body: some View {
        ZStack {
            content
        }
        .foregroundStyle(.white)
        .colorScheme(.dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(background)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .contentShape(Rectangle())
    }
}
