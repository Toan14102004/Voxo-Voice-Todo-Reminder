//
//  VoxoCards.swift
//  VoxoDesign
//
//  DS / Components: List card 165×120, Event card 282×62, Stat card 165×108,
//  Progress card 342×92, Details card 342×208.
//

import SwiftUI
import VoxoShared

/// One list on the Lists tab: icon tinted with the list colour, name, and how many tasks it holds.
public struct VoxoListCard: View {
    private let icon: String
    private let name: String
    private let count: Int
    private let tint: Color

    public init(icon: String = VoxoIcon.home, name: String, count: Int, tint: Color) {
        self.icon = icon
        self.name = name
        self.count = count
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: VoxoSpacing.s) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(tint)

            Spacer(minLength: 0)

            // The list name is user data; only the count below it is localized.
            Text(verbatim: name)
                .font(VoxoFont.headline)
                .foregroundStyle(VoxoColor.textPrimary)
                .lineLimit(1)

            Text("\(count) tasks")
                .font(VoxoFont.caption)
                .foregroundStyle(VoxoColor.textSecondary)
        }
        .padding(VoxoSpacing.l)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        // The design tints each card with its own list colour rather than using a neutral surface.
        .background(tint.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.card, style: .continuous))
    }
}

/// The "Danh sách mới" cell closing the grid: outlined, so it reads as an action.
public struct VoxoNewListCard: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: VoxoSpacing.s) {
                Image(systemName: VoxoIcon.add)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(VoxoColor.primary)

                Spacer(minLength: 0)

                Text("New list")
                    .font(VoxoFont.headline)
                    .foregroundStyle(VoxoColor.primary)

                Text("Pick a colour and icon")
                    .font(VoxoFont.caption)
                    .foregroundStyle(VoxoColor.textSecondary)
            }
            .padding(VoxoSpacing.l)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(VoxoColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: VoxoRadius.card, style: .continuous)
                    .strokeBorder(VoxoColor.border, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }
}

/// A row in "Lọc thông minh": icon, label, and how many tasks match.
public struct VoxoSmartFilterRow: View {
    private let icon: String
    private let title: LocalizedStringKey
    private let count: Int
    private let action: () -> Void

    public init(icon: String, title: LocalizedStringKey, count: Int, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.count = count
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: VoxoSpacing.m) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(VoxoColor.textSecondary)
                    .frame(width: 24)

                Text(title)
                    .font(VoxoFont.body)
                    .foregroundStyle(VoxoColor.textPrimary)

                Spacer(minLength: VoxoSpacing.s)

                Text(verbatim: "\(count)")
                    .font(VoxoFont.bodyEmphasis)
                    .foregroundStyle(VoxoColor.textSecondary)
            }
            .padding(.horizontal, VoxoSpacing.l)
            .frame(minHeight: VoxoHitTarget.minimum + 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// A scheduled item on the Calendar tab, with a coloured spine on the leading edge.
public struct VoxoEventCard: View {
    private let title: String
    private let detail: String
    private let tint: Color

    public init(title: String, detail: String, tint: Color) {
        self.title = title
        self.detail = detail
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: VoxoSpacing.m) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(tint)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: title)
                    .font(VoxoFont.headline)
                    .foregroundStyle(VoxoColor.textPrimary)
                Text(verbatim: detail)
                    .font(VoxoFont.caption)
                    .foregroundStyle(VoxoColor.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, VoxoSpacing.m)
        .padding(.horizontal, VoxoSpacing.m)
        .frame(minHeight: 62)
        // Tinted with the list colour, like the Calendar design, not a neutral surface.
        .background(tint.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.card, style: .continuous))
    }
}

/// A single headline number on the Stats tab — "12 ngày / Chuỗi liên tiếp".
public struct VoxoStatCard: View {
    private let icon: String
    private let value: String
    private let label: LocalizedStringKey
    private let tint: Color

    public init(icon: String, value: String, label: LocalizedStringKey, tint: Color) {
        self.icon = icon
        self.value = value
        self.label = label
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: VoxoSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(tint)

            Spacer(minLength: 0)

            Text(verbatim: value)
                .font(VoxoFont.display)
                .foregroundStyle(VoxoColor.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(label)
                .font(VoxoFont.caption)
                .foregroundStyle(VoxoColor.textSecondary)
        }
        .padding(VoxoSpacing.l)
        // Two per row on the Stats tab, so it shares the width rather than fixing the design's 165.
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.card, style: .continuous))
    }
}

/// "Tiến độ hôm nay · 3/7 việc đã xong · 43%" on the brand colour.
public struct VoxoProgressCard: View {
    private let done: Int
    private let total: Int

    public init(done: Int, total: Int) {
        self.done = done
        self.total = total
    }

    private var fraction: Double {
        total > 0 ? Double(done) / Double(total) : 0
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: VoxoSpacing.s) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's progress")
                        .font(VoxoFont.caption)
                    Text("\(done)/\(total) tasks done")
                        .font(VoxoFont.title)
                }
                Spacer(minLength: 0)
                Text(fraction.formatted(.percent.precision(.fractionLength(0))))
                    .font(VoxoFont.display)
            }

            // The bar repeats the numbers, so nothing depends on seeing the fill (DS / Rules).
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(VoxoColor.textOnAccent.opacity(0.25))
                    Capsule()
                        .fill(VoxoColor.textOnAccent)
                        .frame(width: max(0, proxy.size.width * fraction))
                }
            }
            .frame(height: 6)
        }
        .foregroundStyle(VoxoColor.textOnAccent)
        .padding(VoxoSpacing.l)
        .frame(height: 92)
        .background(VoxoColor.primary)
        .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Task detail: one labelled row per attribute (Hạn chót / Nhắc nhở / Lặp lại / Danh sách).
public struct VoxoDetailsCard<Rows: View>: View {
    private let rows: Rows

    public init(@ViewBuilder rows: () -> Rows) {
        self.rows = rows()
    }

    public var body: some View {
        VStack(spacing: 0) { rows }
            .background(VoxoColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.card, style: .continuous))
    }
}

public struct VoxoDetailRow: View {
    private let icon: String
    private let label: LocalizedStringKey
    private let value: String
    private let showsChevron: Bool
    private let action: (() -> Void)?

    public init(
        icon: String,
        label: LocalizedStringKey,
        value: String,
        showsChevron: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.label = label
        self.value = value
        self.showsChevron = showsChevron
        self.action = action
    }

    public var body: some View {
        if let action {
            Button(action: action) { content }.buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: VoxoSpacing.m) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(VoxoColor.textSecondary)
                .frame(width: 24)

            Text(label)
                .font(VoxoFont.body)
                .foregroundStyle(VoxoColor.textSecondary)

            Spacer(minLength: VoxoSpacing.s)

            Text(verbatim: value)
                .font(VoxoFont.bodyEmphasis)
                .foregroundStyle(VoxoColor.textPrimary)
                .multilineTextAlignment(.trailing)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(VoxoColor.textMuted)
            }
        }
        .padding(.horizontal, VoxoSpacing.l)
        .frame(minHeight: VoxoHitTarget.minimum + 8)
        .contentShape(Rectangle())
    }
}
