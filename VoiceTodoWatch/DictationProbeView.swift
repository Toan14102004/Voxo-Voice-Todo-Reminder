//
//  DictationProbeView.swift
//  VoiceTodoWatch
//
//  Phase 0 harness. Throwaway code: delete once PLAN.md Phase 0 is signed off.
//

import SwiftUI

struct DictationProbeView: View {
    @StateObject private var probe = DictationProbe()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(probe.verdict)
                            .font(.headline)
                        Text("\(probe.recordedCount)/\(probe.samples.count) câu · \(probe.passedCount) đạt · \(probe.totalWordErrors) từ sai")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(probe.samples) { sample in
                    NavigationLink {
                        DictationSampleView(sample: sample, probe: probe)
                    } label: {
                        row(for: sample)
                    }
                }

                Section {
                    Button("Xoá kết quả", role: .destructive, action: probe.reset)
                }
            }
            .navigationTitle("Phase 0")
        }
    }

    private func row(for sample: DictationSample) -> some View {
        HStack(alignment: .top, spacing: 6) {
            icon(for: sample)
            VStack(alignment: .leading, spacing: 1) {
                Text(sample.expected)
                    .font(.caption)
                    .lineLimit(2)
                if let errors = sample.wordErrors {
                    Text(errors == 0 ? "đúng hết" : "sai \(errors) từ")
                        .font(.caption2)
                        .foregroundStyle(errors <= 1 ? Color.secondary : Color.red)
                }
            }
        }
    }

    private func icon(for sample: DictationSample) -> some View {
        Group {
            switch sample.passes {
            case .none: Image(systemName: "circle.dotted").foregroundStyle(.secondary)
            case .some(true): Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case .some(false): Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
            }
        }
        .font(.caption)
    }
}

/// Shows the sentence to read aloud, then scores whatever dictation produced.
struct DictationSampleView: View {
    let sample: DictationSample
    let probe: DictationProbe

    @Environment(\.dismiss) private var dismiss
    @State private var typed: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Đọc câu này:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(sample.expected)
                    .font(.headline)

                // On watchOS, tapping a TextField opens the system input screen where dictation lives.
                // PLAN.md v1 uses that, not SFSpeechRecognizer.
                TextField("Nói vào đây", text: $typed)

                Button("Lưu") {
                    probe.record(typed, for: sample.id)
                    dismiss()
                }
                .disabled(typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if let errors = sample.wordErrors {
                    Divider()
                    Text("Lần trước: sai \(errors) từ, \(sample.attempts) lượt")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(sample.dictated)
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 2)
        }
        .onAppear { typed = sample.dictated }
    }
}
