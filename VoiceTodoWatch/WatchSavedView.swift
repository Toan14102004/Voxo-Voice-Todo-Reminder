//
//  WatchSavedView.swift
//  VoiceTodoWatch
//
//  Design: frame "Watch / Apple / 5 Đã lưu" — closes itself after two seconds, with undo.
//

import SwiftUI
import VoxoDesign

struct WatchSavedView: View {
    let title: String
    let detail: String?
    let onUndo: () -> Void
    let onFinish: () -> Void

    /// The design's "Tự đóng sau 2 giây".
    private static let dwell: Duration = .seconds(2)

    var body: some View {
        VStack(spacing: VoxoSpacing.s) {
            ZStack {
                Circle().fill(VoxoColor.success)
                Image(systemName: VoxoIcon.check)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(VoxoColor.textOnAccent)
            }
            .frame(width: 64, height: 64)

            Text("Added!")
                .font(VoxoFont.headline)
                .foregroundStyle(VoxoColor.textPrimary)

            Text(verbatim: [title, detail].compactMap { $0 }.joined(separator: " · "))
                .font(VoxoFont.caption)
                .foregroundStyle(VoxoColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Button("Undo", action: onUndo)
                .buttonStyle(VoxoSecondaryButtonStyle())
        }
        .padding(.horizontal, VoxoSpacing.screenMargin)
        .task {
            // Cancelled automatically if the screen goes away first — tapping Undo dismisses,
            // which tears the task down before it can fire.
            try? await Task.sleep(for: Self.dwell)
            onFinish()
        }
    }
}
