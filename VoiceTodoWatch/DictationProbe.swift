//
//  DictationProbe.swift
//  VoiceTodoWatch
//
//  Phase 0 harness. Throwaway code: delete once PLAN.md Phase 0 is signed off.
//

import Combine
import Foundation

struct DictationSample: Codable, Identifiable {
    let id: Int
    let expected: String
    var dictated: String = ""
    var attempts: Int = 0
    var recordedAt: Date?

    var wordErrors: Int? {
        guard recordedAt != nil else { return nil }
        return WordDiff.editDistance(expected: expected, actual: dictated)
    }

    /// PLAN.md §0 pass bar: the user corrects at most one word per sentence.
    var passes: Bool? {
        guard let wordErrors else { return nil }
        return wordErrors <= 1
    }
}

/// Ten todo-shaped Vietnamese sentences, all with tone marks.
private let defaultSentences = [
    "Mua sữa cho con",
    "Gọi điện cho mẹ lúc tám giờ tối",
    "Họp nhóm dự án thứ ba tuần sau",
    "Đổ rác trước khi đi làm",
    "Uống thuốc sau khi ăn cơm",
    "Đặt vé máy bay đi Đà Nẵng",
    "Trả tiền điện nước tháng này",
    "Tập thể dục ba mươi phút",
    "Nhắc anh Tuấn gửi báo giá",
    "Mang laptop đi sửa bàn phím"
]

final class DictationProbe: ObservableObject {
    private static let storageKey = "phase0.dictation.samples"

    @Published private(set) var samples: [DictationSample]

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([DictationSample].self, from: data),
           decoded.count == defaultSentences.count {
            samples = decoded
        } else {
            samples = defaultSentences.enumerated().map { DictationSample(id: $0.offset, expected: $0.element) }
        }
    }

    var recordedCount: Int { samples.filter { $0.recordedAt != nil }.count }
    var passedCount: Int { samples.filter { $0.passes == true }.count }
    var totalWordErrors: Int { samples.compactMap(\.wordErrors).reduce(0, +) }

    /// Phase 0 passes only when every sentence has been read and each needed at most one fix.
    var verdict: String {
        guard recordedCount == samples.count else { return "Còn \(samples.count - recordedCount) câu" }
        return passedCount == samples.count ? "ĐẠT" : "KHÔNG ĐẠT (\(samples.count - passedCount) câu sai >1 từ)"
    }

    func record(_ dictated: String, for id: Int) {
        guard let index = samples.firstIndex(where: { $0.id == id }) else { return }
        samples[index].dictated = dictated.trimmingCharacters(in: .whitespacesAndNewlines)
        samples[index].attempts += 1
        samples[index].recordedAt = Date()
        persist()
    }

    func reset() {
        samples = defaultSentences.enumerated().map { DictationSample(id: $0.offset, expected: $0.element) }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(samples) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
