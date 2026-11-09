//
//  TodoPriority.swift
//  VoxoShared
//

import Foundation

/// Priority levels from the Tidy design (DS / Colors: Cao / Vừa / Thấp).
///
/// Stored as Int16 so ordering is meaningful in fetch sorts.
public enum TodoPriority: Int16, Codable, CaseIterable, Sendable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3
}

/// How often the task itself recurs.
///
/// Not to be confused with `intervalOverride`, which is how often an unfinished task *nags*.
public enum RepeatRule: String, Codable, CaseIterable, Sendable {
    case daily
    case weekly
}

public extension TodoPriority {
    /// Ordered for pickers: highest first, "none" last, which is how people scan the list.
    static var pickerOrder: [TodoPriority] { [.high, .medium, .low, .none] }
}
