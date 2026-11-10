//
//  VoxoStatsCharts.swift
//  VoxoDesign
//
//  DS / Components, Stats tab: the daily bar chart and the per-list progress row.
//

import SwiftUI

/// One column of the "Việc hoàn thành mỗi ngày" chart.
public struct VoxoBarChartEntry: Identifiable, Equatable {
    public let id: Int
    public let label: String
    public let value: Int
    public let isHighlighted: Bool

    public init(id: Int, label: String, value: Int, isHighlighted: Bool) {
        self.id = id
        self.label = label
        self.value = value
        self.isHighlighted = isHighlighted
    }
}

/// Completions per day. The highlighted column is solid and carries its number above it; the rest
/// are drawn in a lighter tint.
public struct VoxoBarChart: View {
    private let entries: [VoxoBarChartEntry]
    private let height: CGFloat

    public init(entries: [VoxoBarChartEntry], height: CGFloat = 170) {
        self.entries = entries
        self.height = height
    }

    private var peak: Int {
        max(entries.map(\.value).max() ?? 0, 1)
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: VoxoSpacing.s) {
            ForEach(entries) { entry in
                column(entry)
            }
        }
        .frame(height: height, alignment: .bottom)
    }

    private func column(_ entry: VoxoBarChartEntry) -> some View {
        // The bar area is sized here rather than by the bar itself, so every column's baseline
        // and label line up even when a day has nothing in it.
        let barArea = height - 44

        return VStack(spacing: VoxoSpacing.xs) {
            Text(verbatim: entry.isHighlighted ? "\(entry.value)" : " ")
                .font(VoxoFont.caption)
                .foregroundStyle(VoxoColor.primary)

            Spacer(minLength: 0)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(entry.isHighlighted ? VoxoColor.primary : VoxoColor.primary.opacity(0.35))
                // An empty day keeps a visible stub, so the column reads as "zero" and not as
                // a missing bar.
                .frame(height: max(6, barArea * CGFloat(entry.value) / CGFloat(peak)))

            Text(verbatim: entry.label)
                .font(VoxoFont.caption)
                .foregroundStyle(entry.isHighlighted ? VoxoColor.primary : VoxoColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: entry.label))
        .accessibilityValue(Text("\(entry.value) tasks"))
    }
}

/// A row of "Theo danh sách": list icon and name, "6/8", and a bar in the list's own colour.
public struct VoxoListProgressRow: View {
    private let icon: String
    private let name: String
    private let done: Int
    private let total: Int
    private let tint: Color

    public init(icon: String, name: String, done: Int, total: Int, tint: Color) {
        self.icon = icon
        self.name = name
        self.done = done
        self.total = total
        self.tint = tint
    }

    private var fraction: Double {
        total > 0 ? Double(done) / Double(total) : 0
    }

    public var body: some View {
        VStack(spacing: VoxoSpacing.s) {
            HStack(spacing: VoxoSpacing.s) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(tint)
                    .frame(width: 24)

                Text(verbatim: name)
                    .font(VoxoFont.headline)
                    .foregroundStyle(VoxoColor.textPrimary)

                Spacer(minLength: 0)

                Text(verbatim: "\(done)/\(total)")
                    .font(VoxoFont.body)
                    .foregroundStyle(VoxoColor.textSecondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(VoxoColor.border)
                    Capsule()
                        .fill(tint)
                        .frame(width: max(0, proxy.size.width * fraction))
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
    }
}
