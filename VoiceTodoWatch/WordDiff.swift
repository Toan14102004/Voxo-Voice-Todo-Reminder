//
//  WordDiff.swift
//  VoiceTodoWatch
//
//  Phase 0 harness. Throwaway code: delete once PLAN.md Phase 0 is signed off.
//

import Foundation

/// Word-level comparison used to score dictation accuracy.
///
/// Diacritics are deliberately preserved — the whole point of the Phase 0 probe is whether Watch
/// dictation gets Vietnamese tone marks right, so "dò" and "do" must count as different words.
enum WordDiff {
    /// Lowercases, strips punctuation and collapses whitespace, keeping diacritics intact.
    static func words(_ text: String) -> [String] {
        let stripped = text.unicodeScalars
            .map { CharacterSet.punctuationCharacters.contains($0) ? " " : Character($0) }
            .reduce(into: "") { $0.append($1) }

        return stripped
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
    }

    /// Minimum number of word insert/delete/substitute operations to turn `expected` into `actual`.
    /// This is the "số từ phải sửa" figure Phase 0 measures against.
    static func editDistance(expected: String, actual: String) -> Int {
        let source = words(expected)
        let target = words(actual)

        if source.isEmpty { return target.count }
        if target.isEmpty { return source.count }

        var previous = Array(0...target.count)
        var current = [Int](repeating: 0, count: target.count + 1)

        for (i, sourceWord) in source.enumerated() {
            current[0] = i + 1
            for (j, targetWord) in target.enumerated() {
                let substitution = previous[j] + (sourceWord == targetWord ? 0 : 1)
                current[j + 1] = min(substitution, previous[j + 1] + 1, current[j] + 1)
            }
            swap(&previous, &current)
        }

        return previous[target.count]
    }
}
