//
//  VoxoComponentGallery.swift
//  VoxoDesign
//
//  Every component on one screen, so the build can be held next to the Figma board
//  "DS / Components" and compared. PLAN.md §8 Giai đoạn C acceptance.
//

// iOS only. Not gated on DEBUG either: the package compiles under a configuration named "Dev",
// which Xcode treats as release-type, so DEBUG is not defined inside package targets. The app
// gates the entry point instead.
#if os(iOS)
    import SwiftUI
    import VoxoShared

    public struct VoxoComponentGallery: View {
        @State private var tab: VoxoTab = .today
        @State private var selectedDay = 7
        @State private var quickAddTitle = "Gọi điện cho mẹ"
        @State private var quickAddNote = ""

        public init() {}

        private let now = Date()

        private func todo(_ title: String, done: Bool = false, priority: TodoPriority = .none) -> TodoDTO {
            TodoDTO(
                title: title,
                isDone: done,
                createdAt: now,
                updatedAt: now,
                completedAt: done ? now : nil,
                originDevice: .phone,
                priority: priority
            )
        }

        public var body: some View {
            NavigationStack {
                content
                    .navigationTitle("Components")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }

        private var content: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: VoxoSpacing.xl) {
                    // -galleryBottom skips the first half, so the lower components can be
                    // inspected without scrolling (useful for screenshots).
                    if !ProcessInfo.processInfo.arguments.contains("-galleryBottom") {
                        section("Task row") {
                        TodoRow(todo: todo("Nộp hóa đơn tiền điện", priority: .high),
                                meta: "Hôm qua · Cá nhân", isOverdue: true, onToggle: {})
                        TodoRow(todo: todo("Đọc 20 trang sách", done: true),
                                meta: "Xong lúc 06:30 · Cá nhân", onToggle: {})
                    }

                    section("Chip") {
                        HStack(spacing: VoxoSpacing.s) {
                            VoxoChip(icon: VoxoIcon.date, title: "Today", isSelected: true) {}
                            VoxoChip(icon: VoxoIcon.time, title: "20:00") {}
                        }
                        HStack(spacing: VoxoSpacing.s) {
                            VoxoPriorityChip(.high)
                            VoxoPriorityChip(.medium)
                            VoxoPriorityChip(.low)
                        }
                    }

                    section("Button · FAB") {
                        Button("Start") {}.buttonStyle(VoxoPrimaryButtonStyle())
                        VoxoFAB {}
                    }

                    section("List card · Event card") {
                        HStack(spacing: VoxoSpacing.m) {
                            VoxoListCard(name: "Cá nhân", count: 5, tint: VoxoColor.primary)
                            VoxoListCard(icon: VoxoIcon.list, name: "Công việc", count: 3,
                                         tint: VoxoColor.priorityMedium)
                        }
                        VoxoEventCard(title: "Chạy bộ 5km",
                                      detail: "07:00 – 07:45 · Sức khỏe",
                                      tint: VoxoColor.success)
                    }

                    }
                    section("Stat card · Progress card") {
                        HStack(spacing: VoxoSpacing.m) {
                            VoxoStatCard(icon: VoxoIcon.streak, value: "12",
                                         label: "Day streak", tint: VoxoColor.priorityMedium)
                            VoxoStatCard(icon: VoxoIcon.check, value: "48",
                                         label: "Done this week", tint: VoxoColor.success)
                        }
                        VoxoProgressCard(done: 3, total: 7)
                    }

                    section("Day strip") {
                        HStack(spacing: VoxoSpacing.s) {
                            ForEach(2...8, id: \.self) { day in
                                VoxoDayCell(
                                    weekday: ["T2", "T3", "T4", "T5", "T6", "T7", "CN"][day - 2],
                                    day: "\(day)",
                                    isSelected: selectedDay == day
                                ) { selectedDay = day }
                            }
                        }
                    }

                    section("Details card") {
                        VoxoDetailsCard {
                            VoxoDetailRow(icon: VoxoIcon.date, label: "Due", value: "Hôm nay, 10:00")
                            Divider().padding(.leading, VoxoSpacing.xl + VoxoSpacing.l)
                            VoxoDetailRow(icon: VoxoIcon.alarm, label: "Reminder", value: "Trước 15 phút")
                            Divider().padding(.leading, VoxoSpacing.xl + VoxoSpacing.l)
                            VoxoDetailRow(icon: VoxoIcon.repeatRule, label: "Repeat", value: "Hằng tuần · Thứ 7")
                            Divider().padding(.leading, VoxoSpacing.xl + VoxoSpacing.l)
                            VoxoDetailRow(icon: VoxoIcon.list, label: "List", value: "Công việc",
                                          showsChevron: true) {}
                        }
                    }

                    section("Quick add sheet") {
                        VoxoQuickAddSheet(
                            title: $quickAddTitle,
                            note: $quickAddNote,
                            chips: [
                                .init(icon: VoxoIcon.date, title: "Today", isSelected: true) {},
                                .init(icon: VoxoIcon.time, title: "20:00") {},
                                .init(icon: VoxoIcon.priority, title: "Priority") {},
                                .init(icon: VoxoIcon.home, title: "Personal") {},
                                .init(icon: VoxoIcon.repeatRule, title: "Repeat") {}
                            ],
                            canSubmit: true,
                            onSubmit: {}
                        )
                    }
                }
                .padding(VoxoSpacing.screenMargin)
            }
            .background(VoxoColor.background)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VoxoTabBar(selection: $tab)
            }
        }

        @ViewBuilder
        private func section(
            _ title: LocalizedStringKey,
            @ViewBuilder content: () -> some View
        ) -> some View {
            VStack(alignment: .leading, spacing: VoxoSpacing.m) {
                VoxoSectionHeader(title)
                content()
            }
        }
    }
#endif
