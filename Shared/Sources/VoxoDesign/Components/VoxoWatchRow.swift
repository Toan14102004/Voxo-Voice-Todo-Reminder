//
//  VoxoWatchRow.swift
//  VoxoDesign
//
//  Design "Watch / Apple / 2 Hôm nay". The watch merges the iPhone row's checkbox and priority
//  dot into one ring, because there is no width for both.
//

import SwiftUI

#if os(watchOS)

    public struct VoxoWatchTaskRow: View {
        private let title: String
        private let subtitle: Text?
        private let tint: Color
        private let isDone: Bool
        private let onToggle: () -> Void

        public init(
            title: String,
            subtitle: Text? = nil,
            tint: Color,
            isDone: Bool,
            onToggle: @escaping () -> Void
        ) {
            self.title = title
            self.subtitle = subtitle
            self.tint = tint
            self.isDone = isDone
            self.onToggle = onToggle
        }

        public var body: some View {
            HStack(spacing: VoxoSpacing.m) {
                Button(action: onToggle) { marker }
                    .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: title)
                        .font(VoxoFont.bodyEmphasis)
                        .foregroundStyle(isDone ? VoxoColor.textSecondary : VoxoColor.textPrimary)
                        .lineLimit(2)

                    if let subtitle {
                        subtitle
                            .font(VoxoFont.caption)
                            .foregroundStyle(VoxoColor.textMuted)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, VoxoSpacing.s)
            .padding(.horizontal, VoxoSpacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(VoxoColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.taskRow, style: .continuous))
        }

        /// Filled when done, an open ring otherwise. Shape carries the state, not just colour.
        @ViewBuilder
        private var marker: some View {
            if isDone {
                Circle()
                    .fill(VoxoColor.success)
                    .frame(width: 26, height: 26)
            } else {
                Circle()
                    .strokeBorder(tint, lineWidth: 3)
                    .frame(width: 26, height: 26)
            }
        }
    }

    /// The "Nói để thêm việc" pill that opens dictation. Full width, above the list.
    public struct VoxoWatchAddButton: View {
        private let title: LocalizedStringKey
        private let action: () -> Void

        public init(title: LocalizedStringKey, action: @escaping () -> Void) {
            self.title = title
            self.action = action
        }

        public var body: some View {
            Button(action: action) {
                HStack(spacing: VoxoSpacing.s) {
                    Image(systemName: "mic.fill")
                    Text(title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .font(VoxoFont.bodyEmphasis)
                .foregroundStyle(VoxoColor.textOnAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, VoxoSpacing.m)
                .background(VoxoColor.primaryFill)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

#endif
