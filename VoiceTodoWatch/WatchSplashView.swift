//
//  WatchSplashView.swift
//  VoiceTodoWatch
//
//  A short branded moment at launch. Onboarding itself lives on the iPhone only — a watch
//  session lasts seconds, and nobody reads three pages on their wrist.
//
//  The mark is drawn rather than loaded from an asset: the watch app has its own catalog, and
//  shapes cost nothing and stay sharp at every watch size.
//

import SwiftUI
import VoxoDesign

struct WatchSplashView: View {
    let onFinish: () -> Void

    /// Short on purpose, and shorter than it looks worth making: watchOS already plays its own
    /// launch animation before this appears, and the Core Data stack is built synchronously in
    /// `App.init` before any view exists — so every millisecond here lands on top of a wait the
    /// user has already sat through. Under ~250ms it reads as a glitch; this is just above that.
    private static let dwell: Duration = .milliseconds(380)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        VStack(spacing: VoxoSpacing.m) {
            mark
                .scaleEffect(shown || reduceMotion ? 1 : 0.82)
                .opacity(shown || reduceMotion ? 1 : 0)

            Text(verbatim: "Tidy")
                .font(VoxoFont.title)
                .foregroundStyle(VoxoColor.textPrimary)
                .opacity(shown || reduceMotion ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VoxoColor.background)
        .task {
            withAnimation(.easeOut(duration: 0.28)) { shown = true }
            try? await Task.sleep(for: Self.dwell)
            onFinish()
        }
    }

    /// The app mark: blue rounded square, white tick, amber dot — the same shape the iPhone
    /// onboarding shows.
    private var mark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(VoxoColor.primaryFill)

            Image(systemName: VoxoIcon.check)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(VoxoColor.textOnAccent)

            Circle()
                .fill(VoxoColor.priorityMedium)
                .frame(width: 9, height: 9)
                .offset(x: 21, y: 16)
        }
        .frame(width: 68, height: 68)
        .accessibilityLabel(Text(verbatim: "Tidy"))
    }
}
