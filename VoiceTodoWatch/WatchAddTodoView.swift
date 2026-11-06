//
//  WatchAddTodoView.swift
//  VoiceTodoWatch
//

import SwiftUI
import VoxoDesign

/// PLAN.md §7: a TextField that the user dictates into, and a Save button. Never creates an
/// empty todo.
struct WatchAddTodoView: View {
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""

    private var trimmed: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VoxoSpacing.m) {
                // Tapping this opens the watchOS input screen, where dictation lives. PLAN.md §9
                // keeps SFSpeechRecognizer out of v1.
                TextField("Speak a task", text: $title)
                    .font(VoxoFont.body)

                Button("Save") {
                    onSave(trimmed)
                    dismiss()
                }
                .buttonStyle(VoxoPrimaryButtonStyle())
                .disabled(trimmed.isEmpty)
            }
            .padding(.horizontal, VoxoSpacing.screenMargin)
        }
    }
}
