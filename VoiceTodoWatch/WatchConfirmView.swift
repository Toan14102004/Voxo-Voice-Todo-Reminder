//
//  WatchConfirmView.swift
//  VoiceTodoWatch
//
//  Design: frame "Watch / Apple / 4 Xác nhận".
//
//  The design shows the parse read-only with a "Sửa" button. That button used to only reopen
//  the text field, which is not what the word promises, and left every attribute unchangeable
//  until the task had been saved and reopened. The fields are editable here instead, with the
//  same controls as the detail screen — the parser guesses, and a guess you cannot correct
//  where you made it is worse than no guess.
//
//  The design's bell row says "Nhắc lúc 08:00". Tidy reminds on a repeating cycle until the
//  task is done (PLAN.md §5), not once at the due time, so the row states the cycle.
//

import SwiftUI
import VoxoDesign
import VoxoShared

struct WatchConfirmView: View {
    @Binding var draft: ParsedTask
    @Binding var repeatRule: RepeatRule?
    let lists: [TodoListDTO]
    let intervalMinutes: Int
    let onSave: () -> Void
    let onRetry: () -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        List {
            Section {
                Text(verbatim: draft.title)
                    .font(VoxoFont.bodyEmphasis)
                    .foregroundStyle(VoxoColor.textPrimary)
                    .lineLimit(3)
            } header: {
                Text("Tidy understood:")
            }

            NavigationLink {
                WatchChoiceView(title: "Priority",
                                choices: WatchChoices.priority(),
                                selection: $draft.priority)
            } label: {
                LabeledContent("Priority") { Text(WatchChoices.key(draft.priority)) }
            }

            NavigationLink {
                WatchDueDateView(current: draft.dueAt) { draft.dueAt = $0 }
            } label: {
                LabeledContent("Due") { dueText }
            }

            NavigationLink {
                WatchChoiceView(title: "List",
                                choices: WatchChoices.lists(lists),
                                selection: $draft.listId)
            } label: {
                LabeledContent("List") { listText }
            }

            NavigationLink {
                WatchChoiceView(title: "Repeat",
                                choices: WatchChoices.repeatRules(),
                                selection: $repeatRule)
            } label: {
                LabeledContent("Repeat") { Text(WatchChoices.key(repeatRule)) }
            }

            LabeledContent("Reminder") {
                Text(IntervalLabel.option(minutes: intervalMinutes))
            }

            Button("Save task", action: onSave)
                .buttonStyle(VoxoPrimaryButtonStyle())
                .listRowBackground(Color.clear)

            Button("Say again", action: onRetry)
                .buttonStyle(VoxoSecondaryButtonStyle())
                .listRowBackground(Color.clear)
        }
    }

    private var listText: Text {
        guard let id = draft.listId, let list = lists.first(where: { $0.id == id }) else {
            return Text("None")
        }
        return Text(verbatim: list.name)
    }

    private var dueText: Text {
        guard let dueAt = draft.dueAt else { return Text("None") }
        let time = dueAt.formatted(
            .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(locale)
        )
        if Calendar.current.isDateInToday(dueAt) { return Text("Today \(time)") }
        if Calendar.current.isDateInTomorrow(dueAt) { return Text("Tomorrow \(time)") }
        let day = dueAt.formatted(.dateTime.day().month(.defaultDigits).locale(locale))
        return Text(verbatim: "\(day) \(time)")
    }

}
