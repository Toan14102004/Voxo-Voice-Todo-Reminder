//
//  WatchChoiceView.swift
//  VoiceTodoWatch
//
//  A list of options with a tick on the current one.
//
//  Replaces `Picker` + `.pickerStyle(.navigationLink)`, whose pushed screen rendered with a
//  see-through background inside the add sheet: the options drew on top of the rows underneath,
//  both readable at once. Owning the screen means owning its background.
//

import SwiftUI
import VoxoDesign
import VoxoShared

struct WatchChoice<Value: Hashable>: Identifiable {
    let id: Int
    let value: Value
    let label: Text

    init(_ index: Int, _ value: Value, _ label: Text) {
        id = index
        self.value = value
        self.label = label
    }
}

struct WatchChoiceView<Value: Hashable>: View {
    let title: LocalizedStringKey
    let choices: [WatchChoice<Value>]
    @Binding var selection: Value

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(choices) { choice in
                Button {
                    selection = choice.value
                    dismiss()
                } label: {
                    HStack {
                        choice.label
                            .font(VoxoFont.body)
                            .foregroundStyle(VoxoColor.textPrimary)
                        Spacer(minLength: VoxoSpacing.s)
                        if choice.value == selection {
                            Image(systemName: VoxoIcon.check)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(VoxoColor.Watch.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        // The reason this type exists: an explicit, opaque background behind the whole screen.
        .background(VoxoColor.background.ignoresSafeArea())
        .navigationTitle(title)
    }
}

/// The option lists shared by the confirmation and detail screens, so the two cannot drift.
enum WatchChoices {
    static func priority() -> [WatchChoice<TodoPriority>] {
        TodoPriority.pickerOrder.enumerated().map { index, level in
            WatchChoice(index, level, Text(key(level)))
        }
    }

    static func key(_ priority: TodoPriority) -> LocalizedStringKey {
        switch priority {
        case .high: "High priority"
        case .medium: "Medium priority"
        case .low: "Low priority"
        case .none: "No priority"
        }
    }

    static func lists(_ lists: [TodoListDTO]) -> [WatchChoice<UUID?>] {
        var choices: [WatchChoice<UUID?>] = [WatchChoice(0, nil, Text("None"))]
        for (index, list) in lists.enumerated() {
            choices.append(WatchChoice(index + 1, list.id, Text(verbatim: list.name)))
        }
        return choices
    }

    static func repeatRules() -> [WatchChoice<RepeatRule?>] {
        [
            WatchChoice(0, nil, Text("None")),
            WatchChoice(1, .daily, Text("Repeats daily")),
            WatchChoice(2, .weekly, Text("Repeats weekly"))
        ]
    }

    static func key(_ rule: RepeatRule?) -> LocalizedStringKey {
        switch rule {
        case .daily: "Repeats daily"
        case .weekly: "Repeats weekly"
        case nil: "None"
        }
    }
}
