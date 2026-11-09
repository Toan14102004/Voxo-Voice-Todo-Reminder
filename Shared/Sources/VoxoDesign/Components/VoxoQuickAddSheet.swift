//
//  VoxoQuickAddSheet.swift
//  VoxoDesign
//
//  DS / Components: "Bottom sheet – Thêm nhanh" 390×344, radius 28.
//

import SwiftUI

/// Quick add: title field, note field, a row of attribute chips, a hint, and the confirm button.
///
/// Purely presentational — the chips report taps and the host decides what each one opens.
public struct VoxoQuickAddSheet: View {
    @Binding private var title: String
    @Binding private var note: String

    private let chips: [Chip]
    private let canSubmit: Bool
    private let onSubmit: () -> Void

    public struct Chip: Identifiable {
        public let id = UUID()
        public let icon: String
        public let title: LocalizedStringKey
        public let isSelected: Bool
        public let action: () -> Void

        public init(icon: String, title: LocalizedStringKey, isSelected: Bool = false, action: @escaping () -> Void) {
            self.icon = icon
            self.title = title
            self.isSelected = isSelected
            self.action = action
        }
    }

    public init(
        title: Binding<String>,
        note: Binding<String>,
        chips: [Chip],
        canSubmit: Bool,
        onSubmit: @escaping () -> Void
    ) {
        _title = title
        _note = note
        self.chips = chips
        self.canSubmit = canSubmit
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: VoxoSpacing.l) {
            Capsule()
                .fill(VoxoColor.border)
                .frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)

            TextField("What needs doing?", text: $title, axis: .vertical)
                .font(VoxoFont.title)
                .lineLimit(1...3)

            TextField("Add a note…", text: $note, axis: .vertical)
                .font(VoxoFont.body)
                .foregroundStyle(VoxoColor.textSecondary)
                .lineLimit(1...3)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: VoxoSpacing.s) {
                    ForEach(chips) { chip in
                        VoxoChip(
                            icon: chip.icon,
                            title: chip.title,
                            isSelected: chip.isSelected,
                            action: chip.action
                        )
                    }
                }
            }

            Text("Tip: type \"tomorrow 8am\" to set the date automatically")
                .font(VoxoFont.caption)
                .foregroundStyle(VoxoColor.textMuted)

            Button("Add task", action: onSubmit)
                .buttonStyle(VoxoPrimaryButtonStyle())
                .disabled(!canSubmit)
        }
        .padding(.horizontal, VoxoSpacing.xl)
        .padding(.top, VoxoSpacing.m)
        .padding(.bottom, VoxoSpacing.xl)
    }
}
