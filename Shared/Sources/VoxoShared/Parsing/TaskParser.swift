//
//  TaskParser.swift
//  VoxoShared
//
//  PLAN.md §1.10, reopened 11/11/2026: turn one dictated sentence into a task with a time,
//  a list and a priority.
//
//  No `SFSpeechRecognizer` anywhere — `Speech.framework` does not exist in the watchOS SDK, and
//  it is not needed: system dictation already hands back text. Everything here works on that text,
//  so the same parser runs on both devices and is testable without a microphone.
//

import Foundation

/// What one sentence turned into.
public struct ParsedTask: Equatable, Sendable {
    /// The sentence with the recognised parts taken out. Never empty.
    public var title: String
    public var dueAt: Date?
    public var listId: UUID?
    public var priority: TodoPriority
    /// The exact phrases that were consumed, for the confirmation screen to show back.
    public var recognised: [String]

    public init(
        title: String,
        dueAt: Date? = nil,
        listId: UUID? = nil,
        priority: TodoPriority = .none,
        recognised: [String] = []
    ) {
        self.title = title
        self.dueAt = dueAt
        self.listId = listId
        self.priority = priority
        self.recognised = recognised
    }

    /// Whether the parser found anything worth confirming.
    public var isStructured: Bool {
        dueAt != nil || listId != nil || priority != .none
    }
}

public enum TaskParser {
    /// Words that mean "high priority" when spoken. Only the top level is detected: nobody says
    /// "ưu tiên vừa" out loud.
    private static let urgentWords = [
        "gấp", "khẩn", "khẩn cấp", "quan trọng", "ưu tiên cao",
        "urgent", "important", "asap", "high priority"
    ]

    /// Filler left behind once a time phrase is removed — "họp lúc" should not keep its "lúc".
    private static let danglingWords = [
        "lúc", "vào", "vào lúc", "ngày", "hồi",
        "at", "on", "by", "in"
    ]

    public static func parse(
        _ text: String,
        lists: [TodoListDTO] = [],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> ParsedTask {
        let original = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !original.isEmpty else { return ParsedTask(title: "") }

        var cuts: [Range<String.Index>] = []
        var recognised: [String] = []

        // 1. Time.
        var dueAt: Date?
        if let match = firstDate(in: original) {
            dueAt = resolve(match.date, now: now, calendar: calendar)
            cuts.append(match.range)
            recognised.append(String(original[match.range]))
        }

        // 2. List, matched on its own name, ignoring case and diacritics so "cong viec" lands on
        //    "Công việc" — dictation does not always return the marks.
        var listId: UUID?
        if let hit = firstList(in: original, lists: lists) {
            listId = hit.id
            cuts.append(hit.range)
            recognised.append(String(original[hit.range]))
        }

        // 3. Priority.
        var priority = TodoPriority.none
        if let hit = firstPhrase(urgentWords, in: original) {
            priority = .high
            cuts.append(hit)
            recognised.append(String(original[hit]))
        }

        let title = cleanedTitle(from: original, removing: cuts)
        return ParsedTask(
            // Everything recognised and nothing left is possible — "ngày mai" on its own. Keeping
            // the sentence beats storing a blank task.
            title: title.isEmpty ? original : title,
            dueAt: dueAt,
            listId: listId,
            priority: priority,
            recognised: recognised
        )
    }

    // MARK: - Time

    private static func firstDate(in text: String) -> (date: Date, range: Range<String.Index>)? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        else { return nil }

        let ns = text as NSString
        let matches = detector.matches(in: text, range: NSRange(location: 0, length: ns.length))
        for match in matches {
            guard let date = match.date, let range = Range(match.range, in: text) else { continue }
            return (date, range)
        }
        return nil
    }

    /// A reminder in the past is useless, and the detector resolves a bare "7h sáng" against
    /// today. When the result has already gone by but still falls on today, move it to tomorrow.
    /// An explicit past date — "thứ sáu tuần trước" — is left alone: the user meant it.
    private static func resolve(_ date: Date, now: Date, calendar: Calendar) -> Date {
        guard date < now, calendar.isDate(date, inSameDayAs: now) else { return date }
        return calendar.date(byAdding: .day, value: 1, to: date) ?? date
    }

    // MARK: - List and priority

    private static func firstList(
        in text: String,
        lists: [TodoListDTO]
    ) -> (id: UUID, range: Range<String.Index>)? {
        // Longest name first, so "Mua sắm gia dụng" wins over "Mua sắm".
        for list in lists.sorted(by: { $0.name.count > $1.name.count }) {
            if let range = range(of: list.name, in: text) {
                return (list.id, range)
            }
        }
        return nil
    }

    private static func firstPhrase(_ phrases: [String], in text: String) -> Range<String.Index>? {
        for phrase in phrases.sorted(by: { $0.count > $1.count }) {
            if let range = range(of: phrase, in: text) { return range }
        }
        return nil
    }

    private static func range(of needle: String, in text: String) -> Range<String.Index>? {
        text.range(
            of: needle,
            options: [.caseInsensitive, .diacriticInsensitive],
            range: nil,
            locale: nil
        )
    }

    // MARK: - Title

    private static func cleanedTitle(
        from text: String,
        removing cuts: [Range<String.Index>]
    ) -> String {
        var result = text
        // Back to front, so earlier ranges stay valid as later ones are removed.
        for cut in cuts.sorted(by: { $0.lowerBound > $1.lowerBound }) {
            result.removeSubrange(cut)
        }

        var words = result
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        // Drop connectives the removed phrase left hanging, at either end.
        while let last = words.last, isDangling(last) { words.removeLast() }
        while let first = words.first, isDangling(first) { words.removeFirst() }

        return words.joined(separator: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: " ,.;:-–—"))
    }

    private static func isDangling(_ word: String) -> Bool {
        let cleaned = word.trimmingCharacters(in: CharacterSet(charactersIn: " ,.;:-–—"))
        guard !cleaned.isEmpty else { return true }
        return danglingWords.contains {
            cleaned.compare($0, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }
}
