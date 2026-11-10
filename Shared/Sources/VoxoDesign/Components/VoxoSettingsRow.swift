//
//  VoxoSettingsRow.swift
//  VoxoDesign
//
//  Design "VI / 8 Cài đặt": the grouped rows and the progress card at the top.
//

import SwiftUI

/// One row of the Settings screen.
///
/// The emphasis is the opposite of `VoxoDetailRow`: here the **label** is what you read and the
/// value is the current choice, so the label is primary and the value is secondary — or accent,
/// for the one row the design highlights.
public struct VoxoSettingsRow: View {
    public enum ValueStyle {
        case normal
        case accent
    }

    /// A row's value is either user data or a translated choice. Keeping both cases means a
    /// caller never has to resolve a key itself, which would freeze the row's language.
    private enum Value {
        case none
        case verbatim(String)
        case key(LocalizedStringKey)
    }

    private let icon: String
    private let label: LocalizedStringKey
    private let value: Value
    private let valueStyle: ValueStyle
    private let showsChevron: Bool

    /// For values that are user data — a language's own name, a list name, "CSV".
    public init(
        icon: String,
        label: LocalizedStringKey,
        value: String? = nil,
        valueStyle: ValueStyle = .normal,
        showsChevron: Bool = true
    ) {
        self.init(
            icon: icon,
            label: label,
            value: value.map(Value.verbatim) ?? .none,
            valueStyle: valueStyle,
            showsChevron: showsChevron
        )
    }

    /// For values that are a translated choice — "Match system", "Monday", "On".
    public init(
        icon: String,
        label: LocalizedStringKey,
        value: LocalizedStringKey,
        valueStyle: ValueStyle = .normal,
        showsChevron: Bool = true
    ) {
        self.init(
            icon: icon,
            label: label,
            value: Value.key(value),
            valueStyle: valueStyle,
            showsChevron: showsChevron
        )
    }

    private init(
        icon: String,
        label: LocalizedStringKey,
        value: Value,
        valueStyle: ValueStyle,
        showsChevron: Bool
    ) {
        self.icon = icon
        self.label = label
        self.value = value
        self.valueStyle = valueStyle
        self.showsChevron = showsChevron
    }

    public var body: some View {
        HStack(spacing: VoxoSpacing.m) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(VoxoColor.textSecondary)
                .frame(width: 26)

            Text(label)
                .font(VoxoFont.body)
                .foregroundStyle(VoxoColor.textPrimary)

            Spacer(minLength: VoxoSpacing.s)

            valueText
                .font(VoxoFont.body)
                .foregroundStyle(valueStyle == .accent ? VoxoColor.primary : VoxoColor.textSecondary)
                .multilineTextAlignment(.trailing)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(VoxoColor.textMuted)
            }
        }
        .padding(.horizontal, VoxoSpacing.l)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var valueText: some View {
        switch value {
        case .none: EmptyView()
        case let .verbatim(text): Text(verbatim: text)
        case let .key(key): Text(key)
        }
    }
}

/// The card above the first group: how the user is doing, not who they are. Tidy has no account
/// system, so the design's name and avatar letter are replaced by the two figures it already shows.
public struct VoxoProfileCard: View {
    private let title: LocalizedStringKey
    private let streak: Int
    private let completed: Int

    public init(title: LocalizedStringKey, streak: Int, completed: Int) {
        self.title = title
        self.streak = streak
        self.completed = completed
    }

    public var body: some View {
        HStack(spacing: VoxoSpacing.m) {
            ZStack {
                Circle().fill(VoxoColor.primaryTint)
                Image(systemName: VoxoIcon.streak)
                    .font(.system(size: 20))
                    .foregroundStyle(VoxoColor.primary)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(VoxoFont.headline)
                    .foregroundStyle(VoxoColor.textPrimary)

                (Text("\(streak) day streak") + Text(verbatim: " · ") + Text("\(completed) done"))
                    .font(VoxoFont.caption)
                    .foregroundStyle(VoxoColor.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(VoxoSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VoxoColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
