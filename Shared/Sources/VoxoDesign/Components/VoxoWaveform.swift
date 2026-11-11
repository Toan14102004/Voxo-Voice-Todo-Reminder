//
//  VoxoWaveform.swift
//  VoxoDesign
//
//  The voice affordance from the "Speak to Add" mockup.
//

import SwiftUI

/// An idling sound wave, drawn to say "this is where you talk".
///
/// **It does not follow the voice, and cannot.** Dictation runs in the watchOS input screen,
/// which takes the whole display and exposes no audio levels, so there is nothing to follow —
/// and by then this view is not even on screen. Reading the microphone to drive it would mean
/// recording the audio ourselves and shipping it to the phone to transcribe, which costs the
/// Watch its ability to work without the phone (PLAN.md §1.11).
///
/// Treat it as decoration with a job: it marks the control as voice input, nothing more.
public struct VoxoWaveform: View {
    private let tint: Color
    private let height: CGFloat

    public init(tint: Color = VoxoColor.primary, height: CGFloat = 44) {
        self.tint = tint
        self.height = height
    }

    public var body: some View {
        // 20fps rather than the display's full rate: this is background decoration on a watch,
        // and the difference is invisible while the battery cost is not.
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            Canvas { context, size in
                let phase = timeline.date.timeIntervalSinceReferenceDate
                draw(in: &context, size: size, phase: phase)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }

    /// Three sine waves at different speeds, so the shape never repeats in an obvious way.
    private func draw(in context: inout GraphicsContext, size: CGSize, phase: Double) {
        let layers: [(amplitude: Double, length: Double, speed: Double, opacity: Double)] = [
            (0.42, 1.0, 1.1, 1.00),
            (0.30, 1.7, -0.8, 0.55),
            (0.18, 2.6, 1.6, 0.30)
        ]

        for layer in layers {
            var path = Path()
            let midY = size.height / 2
            let steps = 48

            for step in 0...steps {
                let x = size.width * Double(step) / Double(steps)
                // Taper to nothing at both ends, so the wave floats instead of being clipped.
                let envelope = sin(Double(step) / Double(steps) * .pi)
                let angle = (x / size.width) * .pi * 2 * layer.length + phase * layer.speed
                let y = midY + sin(angle) * midY * layer.amplitude * envelope

                if step == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            let colour = tint.opacity(layer.opacity)
            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [colour.opacity(0.1), colour, colour.opacity(0.1)]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: 0)
                ),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
            )
        }
    }
}
