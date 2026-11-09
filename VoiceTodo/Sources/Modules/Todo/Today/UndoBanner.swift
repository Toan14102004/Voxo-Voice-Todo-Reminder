//
//  UndoBanner.swift
//  VoiceTodo
//

import Combine
import Foundation
import SwiftUI
import VoxoDesign
import VoxoShared

/// DS / Rules: "Hoàn tác 4s" — every destructive or state-changing swipe can be taken back.
///
/// Holds the action rather than the undone data, so the caller decides how to reverse it.
@MainActor
final class UndoCenter: ObservableObject {
    struct Pending: Identifiable {
        let id = UUID()
        let message: LocalizedStringKey
        let undo: () -> Void
    }

    @Published private(set) var pending: Pending?

    static let window: TimeInterval = 4

    private var task: Task<Void, Never>?

    func offer(_ message: LocalizedStringKey, undo: @escaping () -> Void) {
        task?.cancel()
        pending = Pending(message: message, undo: undo)
        task = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Self.window * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.pending = nil
        }
    }

    func performUndo() {
        guard let pending else { return }
        task?.cancel()
        pending.undo()
        self.pending = nil
    }

    func dismiss() {
        task?.cancel()
        pending = nil
    }
}

struct UndoBanner: View {
    let pending: UndoCenter.Pending
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: VoxoSpacing.m) {
            Text(pending.message)
                .font(VoxoFont.body)
                .foregroundStyle(VoxoColor.textOnAccent)

            Spacer(minLength: 0)

            Button("Undo", action: onUndo)
                .font(VoxoFont.headline)
                .foregroundStyle(VoxoColor.textOnAccent)
        }
        .padding(.horizontal, VoxoSpacing.l)
        .frame(minHeight: VoxoHitTarget.minimum + 6)
        .background(VoxoColor.textPrimary)
        .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.card, style: .continuous))
        .padding(.horizontal, VoxoSpacing.screenMargin)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
