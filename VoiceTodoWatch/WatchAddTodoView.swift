//
//  WatchAddTodoView.swift
//  VoiceTodoWatch
//
//  Design: frames "Watch / Apple / 3 Đang nghe", "4 Xác nhận", "5 Đã lưu".
//
//  Frame 3's live waveform is not built, and cannot be: tapping the field hands the whole screen
//  to the watchOS dictation UI, which the app cannot draw behind or read audio levels from —
//  `Speech.framework` does not exist in the watchOS SDK. What the design promises after that
//  point, splitting the sentence into a time, a list and a priority, is real: `TaskParser` does
//  it on the text dictation returns.
//

import SwiftUI
import VoxoDesign
import VoxoShared
import WatchKit

struct WatchAddTodoView: View {
    @ObservedObject var store: WatchTodoStore
    @EnvironmentObject private var session: WatchSessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var stage: Stage = .speaking
    @State private var spoken = ""
    /// The parse, held as editable state so the confirmation screen can correct it before
    /// anything is stored.
    @State private var draft = ParsedTask(title: "")
    /// Not parsed from speech — nobody dictates "lặp lại hằng tuần" — but offered here so the
    /// task can be finished in one pass instead of saving and reopening.
    @State private var repeatRule: RepeatRule?
    @State private var path = NavigationPath()

    private enum Stage: Equatable {
        case speaking
        case confirming
        case saved(TodoDTO)
    }

    var body: some View {
        // A sheet does not inherit the list's NavigationStack, and without one
        // `.pickerStyle(.navigationLink)` has nowhere to push: the options expanded in place and
        // drew over the rows underneath. NavigationLink for the due date was dead for the same
        // reason.
        NavigationStack(path: $path) {
            stages
                #if DEBUG
                    // -choicePreview pushes the priority screen without a tap, so the pushed
                    // view's background can be checked from a script.
                    .navigationDestination(for: String.self) { _ in
                        WatchChoiceView(title: "Priority",
                                        choices: WatchChoices.priority(),
                                        selection: $draft.priority)
                    }
                #endif
        }
    }

    @ViewBuilder
    private var stages: some View {
        Group {
            switch stage {
            case .speaking:
                speaking
            case .confirming:
                WatchConfirmView(
                    draft: $draft,
                    repeatRule: $repeatRule,
                    lists: store.lists,
                    intervalMinutes: session.globalIntervalMinutes,
                    onSave: { save(draft) },
                    onRetry: { retry() }
                )
            case let .saved(todo):
                WatchSavedView(
                    title: todo.title,
                    detail: detail(draft),
                    onUndo: {
                        store.delete(todo)
                        dismiss()
                    },
                    onFinish: { dismiss() }
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: stage)
        #if DEBUG
            // -confirmPreview "<câu>" opens the confirmation screen directly, for screenshots:
            // the dictation step cannot be driven from a script. Parsed here rather than in an
            // initialiser so the real list names are available to match against.
            .task {
                let args = ProcessInfo.processInfo.arguments
                guard let i = args.firstIndex(of: "-confirmPreview"), i + 1 < args.count else { return }
                draft = TaskParser.parse(args[i + 1], lists: store.lists)
                stage = .confirming
                if args.contains("-choicePreview") { path.append("priority") }
            }
        #endif
    }

    private var speaking: some View {
        ScrollView {
            VStack(spacing: VoxoSpacing.s) {
                // Marks the field as voice input. Idle decoration — it does not follow the
                // voice, because by the time anyone speaks, the watchOS dictation screen has
                // taken over the display. See VoxoWaveform.
                VoxoWaveform(tint: VoxoColor.Watch.accent, height: 40)

                Text("Add a task")
                    .font(VoxoFont.headline)
                    .foregroundStyle(VoxoColor.textPrimary)

                // Both icons, because the watchOS input screen this opens offers dictation,
                // the keyboard, Scribble and emoji — and it remembers the last one used. A mic
                // alone made it look voice-only, which is what prompted the question.
                HStack(spacing: VoxoSpacing.s) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(VoxoColor.Watch.accent)
                    Image(systemName: "keyboard")
                        .font(.system(size: 13))
                        .foregroundStyle(VoxoColor.textSecondary)

                    TextField("Speak or type", text: $spoken)
                        .font(VoxoFont.body)
                }
                .padding(.horizontal, VoxoSpacing.m)
                .padding(.vertical, VoxoSpacing.s)
                .background(VoxoColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.taskRow, style: .continuous))

                Button("Continue") { parse() }
                    .buttonStyle(VoxoPrimaryButtonStyle())
                    .disabled(trimmed.isEmpty)
            }
            .padding(.horizontal, VoxoSpacing.screenMargin)
        }
    }

    private var trimmed: String {
        spoken.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parse() {
        draft = TaskParser.parse(trimmed, lists: store.lists)
        // Always confirm now that the screen can be edited: it is the only place to set an
        // attribute before the task exists, not just a review of what the parser guessed.
        stage = .confirming
    }

    private func save(_ parsed: ParsedTask) {
        guard var todo = store.add(parsed: parsed) else {
            dismiss()
            return
        }
        if let repeatRule {
            todo.repeatRule = repeatRule
            store.update(todo)
        }
        WKInterfaceDevice.current().play(.success)
        stage = .saved(todo)
    }

    private func retry() {
        spoken = ""
        stage = .speaking
    }

    /// "Mai 08:00 · Cá nhân" under the title on the saved screen.
    private func detail(_ parsed: ParsedTask) -> String? {
        var parts: [String] = []
        if let dueAt = parsed.dueAt {
            parts.append(dueAt.formatted(
                .dateTime.day().month(.defaultDigits).hour(.twoDigits(amPM: .omitted))
                    .minute(.twoDigits).locale(session.locale)
            ))
        }
        if let name = store.list(id: parsed.listId)?.name { parts.append(name) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
