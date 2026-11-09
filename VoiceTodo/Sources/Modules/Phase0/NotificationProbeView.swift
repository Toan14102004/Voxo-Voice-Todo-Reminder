//
//  NotificationProbeView.swift
//  VoiceTodo
//
//  Phase 0 harness. Throwaway code: delete once PLAN.md Phase 0 is signed off.
//

import SwiftUI
import UserNotifications
import VoxoDesign

struct NotificationProbeView: View {
    /// True when launched straight into the probe via `-phase0Probe`, where there is nothing to dismiss to.
    var isRoot = false

    @Environment(\.dismiss) private var dismiss
    @StateObject private var probe = NotificationProbe()

    @State private var intervalMinutes: Int = 60
    @State private var series: Int = 20
    @State private var firesPerSeries: Int = 3
    @State private var isWorking = false

    /// Series are staggered by one minute on the realistic cycle, so 20 todos x 2 reminders finish
    /// in ~80 minutes instead of 3 hours while still exercising a true 60-minute cadence.
    private var offsetSeconds: Int { intervalMinutes >= 60 ? 60 : 15 }

    /// When the last scheduled reminder is due.
    private var finishesInMinutes: Int {
        (series * offsetSeconds) / 60 + (firesPerSeries - 1) * intervalMinutes
    }

    private var requested: Int { series * firesPerSeries }

    var body: some View {
        NavigationStack {
            Form {
                authorizationSection
                repeatSection
                setupSection
                if probe.run != nil { resultSection }
                reportSection
            }
            .navigationTitle("Phase 0 probe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isRoot {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Đóng") { dismiss() }
                    }
                }
            }
            .task { await probe.refresh() }
        }
    }

    private var authorizationSection: some View {
        Section("Quyền thông báo") {
            LabeledContent("Trạng thái", value: statusText)
            if probe.authorizationStatus != .authorized {
                Button("Xin quyền") {
                    Task { await probe.requestAuthorization() }
                }
            }
        }
    }

    /// Measurement B — the mechanism v1 actually ships (PLAN.md §1.7).
    private var repeatSection: some View {
        Section {
            if let run = probe.repeatRun {
                LabeledContent("Bắt đầu", value: NotificationProbe.stampFormatter.string(from: run.startedAt))
                LabeledContent("Nhịp", value: "\(run.intervalMinutes) phút")
                LabeledContent("Đáng lẽ đã bắn", value: "\(run.expectedFires(now: Date())) lần")
                LabeledContent("Còn trong hàng chờ", value: run.stillPending ? "Có" : "KHÔNG")
                    .foregroundStyle(run.stillPending ? VoxoColor.textPrimary : VoxoColor.danger)

                if let last = run.lastDeliveredAt {
                    LabeledContent("Lần cuối nhận", value: NotificationProbe.stampFormatter.string(from: last))
                }

                Text(run.verdict(now: Date()))
                    .font(.headline)
                    .foregroundStyle(run.verdict(now: Date()).hasPrefix("ĐẠT") ? VoxoColor.success : VoxoColor.danger)

                Button("Thu kết quả nhịp lặp") {
                    Task { await probe.collectRepeating() }
                }
                Button("Dừng nhịp lặp", role: .destructive) {
                    Task { await probe.cancelRepeating() }
                    probe.clearRepeating()
                }
            } else {
                Button("Bắt đầu nhịp lặp 60 phút") {
                    Task { await probe.scheduleRepeating(intervalMinutes: 60) }
                }
                .disabled(probe.authorizationStatus != .authorized)
            }
        } header: {
            Text("B — trigger lặp (cơ chế v1)")
        } footer: {
            Text("Một notification duy nhất, lặp mãi, chiếm 1 slot. Để chạy ít nhất 6 giờ rồi quay lại thu kết quả. Đừng xoá thông báo của Voxo.")
        }
    }

    private var setupSection: some View {
        Section("A — độ chính xác (lên lịch một lần)") {
            Picker("Chu kỳ", selection: $intervalMinutes) {
                Text("5 phút (nhanh)").tag(5)
                Text("60 phút (thật)").tag(60)
            }
            Stepper("Số chuỗi: \(series)", value: $series, in: 1...30)
            Stepper("Mỗi chuỗi: \(firesPerSeries) lần", value: $firesPerSeries, in: 1...5)

            LabeledContent("Tổng", value: "\(requested) notification")
                .foregroundStyle(requested > 60 ? .red : .primary)

            LabeledContent("Chạy xong sau", value: "~\(finishesInMinutes) phút")

            if requested > 60 {
                Text("Trên 60 là chạm trần 64 của iOS, phần vượt sẽ bị bỏ.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button(isWorking ? "Đang lên lịch..." : "Lên lịch \(requested) notification") {
                isWorking = true
                Task {
                    await probe.schedule(
                        intervalMinutes: intervalMinutes,
                        series: series,
                        firesPerSeries: firesPerSeries,
                        offsetSeconds: offsetSeconds
                    )
                    isWorking = false
                }
            }
            .disabled(isWorking || probe.authorizationStatus != .authorized)

            Text("Sau khi bấm: đừng xoá hay chạm vào notification nào cho tới lúc thu kết quả — giờ nhận được đọc từ Notification Center.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        if let run = probe.run {
            Section("Kết quả") {
                LabeledContent("Bắt đầu", value: NotificationProbe.stampFormatter.string(from: run.startedAt))
                LabeledContent("iOS nhận lịch", value: "\(run.registeredPending)/\(run.requested)")
                LabeledContent("Còn chờ", value: "\(probe.pendingNow)")
                LabeledContent("Đã nhận", value: "\(run.deliveredCount)")
                LabeledContent("Đúng giờ (±5p)", value: "\(run.onTimeCount)")

                if let rate = run.onTimeRate {
                    LabeledContent("Tỉ lệ") {
                        Text(String(format: "%.1f%%", rate * 100))
                            .foregroundStyle(rate >= 0.9 ? .green : .red)
                    }
                }
                if let worst = run.worstDelta {
                    LabeledContent("Lệch lớn nhất", value: String(format: "%+.0f giây", worst))
                }
                if let last = run.lastPlannedAt {
                    LabeledContent("Lần cuối hẹn", value: NotificationProbe.stampFormatter.string(from: last))
                }

                Button("Thu kết quả") {
                    Task { await probe.collect() }
                }
            }
        }
    }

    private var reportSection: some View {
        Section("Báo cáo") {
            ScrollView(.horizontal, showsIndicators: true) {
                Text(probe.reportText)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 220)

            Button("Copy báo cáo") {
                UIPasteboard.general.string = probe.reportText
            }

            Button("Huỷ hết notification", role: .destructive) {
                Task { await probe.cancel() }
            }
            Button("Xoá lượt chạy", role: .destructive, action: probe.clearRun)

            if let error = probe.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var statusText: String {
        switch probe.authorizationStatus {
        case .authorized: "Đã cho phép"
        case .denied: "Bị từ chối"
        case .notDetermined: "Chưa hỏi"
        case .provisional: "Tạm thời"
        case .ephemeral: "Ephemeral"
        @unknown default: "Không rõ"
        }
    }
}
