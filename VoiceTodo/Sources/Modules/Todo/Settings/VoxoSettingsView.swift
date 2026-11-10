//
//  VoxoSettingsView.swift
//  VoiceTodo
//
//  Design: frame "VI / 8 Cài đặt".
//
//  Three rows in the design describe things Tidy does not have, and are replaced rather than
//  faked: the profile card has no account behind it, "Sao lưu & đồng bộ · iCloud" is ruled out by
//  PLAN.md §9, and "Giờ nhắc mặc định" assumes a fixed daily time where the app reminds on a
//  repeating cycle (PLAN.md §5). See the Giai đoạn H notes in PLAN.md.
//

import SwiftUI
import UserNotifications
import VoxoDesign
import VoxoShared

struct VoxoSettingsView: View {
    @EnvironmentObject private var store: TodoStore
    @EnvironmentObject private var session: PhoneSessionManager
    @EnvironmentObject private var reminders: ReminderService
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var language = LanguageManager.shared
    @Navigation private var navigation
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VoxoSpacing.l) {
                header
                progressCard
                generalGroup
                otherGroup
                clearGroup
                #if DEBUG
                    diagnosticsGroup
                #endif
                footer
            }
            .padding(.horizontal, VoxoSpacing.screenMargin)
            .padding(.top, VoxoSpacing.l)
            .padding(.bottom, VoxoSpacing.xl)
        }
        .background(VoxoColor.background)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.refresh(reminders: reminders) }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Settings")
                .font(VoxoFont.display)
                .foregroundStyle(VoxoColor.textPrimary)

            Spacer()

            Button("Done") { navigation.goBack() }
                .font(VoxoFont.bodyEmphasis)
                .foregroundStyle(VoxoColor.primary)
        }
    }

    private var progressCard: some View {
        VoxoProfileCard(
            title: "Your progress",
            streak: viewModel.streak(store: store, calendar: settings.calendar),
            completed: store.completed.count
        )
    }

    // MARK: - General

    private var generalGroup: some View {
        VStack(alignment: .leading, spacing: VoxoSpacing.s) {
            VoxoSectionHeader("General")

            VoxoDetailsCard {
                Menu {
                    Picker("Language", selection: languageBinding) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(verbatim: option.nativeName).tag(option)
                        }
                    }
                } label: {
                    VoxoSettingsRow(
                        icon: "globe",
                        label: "Language",
                        value: AppLanguage.current().nativeName,
                        valueStyle: .accent
                    )
                }

                Menu {
                    Picker("Appearance", selection: $settings.appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                } label: {
                    VoxoSettingsRow(
                        icon: "circle.lefthalf.filled",
                        label: "Appearance",
                        value: settings.appearance.title
                    )
                }

                Menu {
                    Picker("Reminder cycle", selection: $store.globalIntervalMinutes) {
                        ForEach(SyncSettings.allowedIntervals, id: \.self) { minutes in
                            Text(IntervalLabel.option(minutes: minutes)).tag(minutes)
                        }
                    }
                } label: {
                    VoxoSettingsRow(
                        icon: VoxoIcon.alarm,
                        label: "Reminder cycle",
                        value: IntervalLabel.text(minutes: store.globalIntervalMinutes, isCustom: false)
                    )
                }

                Menu {
                    Picker("Week starts on", selection: $settings.weekStart) {
                        ForEach(WeekStart.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                } label: {
                    VoxoSettingsRow(
                        icon: VoxoIcon.date,
                        label: "Week starts on",
                        value: settings.weekStart.title
                    )
                }
            }
        }
    }

    // MARK: - Other

    private var otherGroup: some View {
        VStack(alignment: .leading, spacing: VoxoSpacing.s) {
            VoxoSectionHeader("Other")

            VoxoDetailsCard {
                Menu {
                    Picker("Sound & haptics", selection: $settings.soundEnabled) {
                        Text("On").tag(true)
                        Text("Off").tag(false)
                    }
                } label: {
                    VoxoSettingsRow(
                        icon: "speaker.wave.2",
                        label: "Sound & haptics",
                        value: settings.soundEnabled ? LocalizedStringKey("On") : "Off"
                    )
                }

                Button {
                    if !viewModel.isAuthorized { viewModel.openSystemSettings() }
                } label: {
                    VoxoSettingsRow(
                        icon: "bell.badge",
                        label: "Notifications",
                        value: viewModel.authorizationText,
                        showsChevron: !viewModel.isAuthorized
                    )
                }
                .buttonStyle(.plain)

                VoxoSettingsRow(
                    icon: "applewatch",
                    label: "Apple Watch sync",
                    value: viewModel.watchStatus(session: session),
                    showsChevron: false
                )

                ShareLink(
                    item: TodoCSV(todos: store.active + store.completed, lists: store.lists),
                    preview: SharePreview("Tidy tasks")
                ) {
                    VoxoSettingsRow(
                        icon: "square.and.arrow.up",
                        label: "Export data",
                        value: "CSV"
                    )
                }
                .buttonStyle(.plain)

                if let feedback = viewModel.feedbackURL {
                    Link(destination: feedback) {
                        VoxoSettingsRow(icon: "bubble.left", label: "Feedback & support")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var clearGroup: some View {
        VoxoDetailsCard {
            Button {
                viewModel.confirmClear = true
            } label: {
                HStack {
                    Text("Clear finished tasks")
                        .font(VoxoFont.body)
                        .foregroundStyle(store.completed.isEmpty ? VoxoColor.textMuted : VoxoColor.danger)
                    Spacer()
                }
                .padding(.horizontal, VoxoSpacing.l)
                .frame(minHeight: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(store.completed.isEmpty)
        }
        .confirmationDialog(
            "Clear \(store.completed.count) finished tasks?",
            isPresented: $viewModel.confirmClear,
            titleVisibility: .visible
        ) {
            Button("Clear", role: .destructive) { store.clearCompleted() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Finished tasks are removed from both devices. This cannot be undone.")
        }
    }

    private var footer: some View {
        (Text(verbatim: "Tidy \(settings.versionText)") + Text(verbatim: " · ")
            + Text("Your data stays on this device"))
            .font(VoxoFont.caption)
            .foregroundStyle(VoxoColor.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.top, VoxoSpacing.s)
    }

    /// Writes through to `LanguageManager` and the keychain, the same pair onboarding sets, so
    /// the choice survives a relaunch.
    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(rawValue: language.currentLanguageCode) ?? .english },
            set: {
                LanguageManager.shared.changeLanguage($0.rawValue)
                KeychainStorage.shared.currentLanguageCode = $0.rawValue
            }
        )
    }

    #if DEBUG
        /// Phase 0/2 check: what is actually scheduled, and when reminders actually arrived.
        private var diagnosticsGroup: some View {
            VStack(alignment: .leading, spacing: VoxoSpacing.s) {
                VoxoSectionHeader("Reminder diagnostics")

                VoxoDetailsCard {
                    VStack(alignment: .leading, spacing: VoxoSpacing.xs) {
                        Text(verbatim: "Đang đặt lịch: \(viewModel.pendingReminders.count)")
                            .font(VoxoFont.caption)

                        ForEach(viewModel.pendingReminders, id: \.identifier) { request in
                            Text(verbatim: request.content.body)
                                .font(VoxoFont.caption)
                            if let info = viewModel.describe(request) {
                                Text(verbatim: "\(info.cadence) · lần tới \(info.next)")
                                    .font(VoxoFont.caption)
                                    .foregroundStyle(VoxoColor.textSecondary)
                            }
                        }

                        if viewModel.deliveredReminders.isEmpty {
                            Text(verbatim: "Chưa nhận được lần nhắc nào")
                                .font(VoxoFont.caption)
                                .foregroundStyle(VoxoColor.textSecondary)
                        } else {
                            ForEach(viewModel.deliveredReminders, id: \.date) { item in
                                Text(verbatim: "đã nhận \(item.date.formatted(date: .omitted, time: .standard))")
                                    .font(VoxoFont.caption)
                            }
                        }

                        Button("Refresh") {
                            Task { await viewModel.refresh(reminders: reminders) }
                        }
                        .font(VoxoFont.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(VoxoSpacing.l)
                }
            }
        }
    #endif
}
