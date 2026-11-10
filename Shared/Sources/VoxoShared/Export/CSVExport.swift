//
//  CSVExport.swift
//  VoxoShared
//

import Foundation

/// Settings → "Xuất dữ liệu · CSV". Pure string building, so the escaping is testable.
public enum CSVExport {
    public static let header = ["title", "status", "priority", "list", "due", "created", "completed", "note"]

    public static func text(todos: [TodoDTO], lists: [TodoListDTO]) -> String {
        let names = Dictionary(lists.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })

        let rows = todos.map { todo in
            [
                todo.title,
                todo.isDone ? "done" : "open",
                name(todo.priority),
                todo.listId.flatMap { names[$0] } ?? "",
                todo.dueAt.map(format) ?? "",
                format(todo.createdAt),
                todo.completedAt.map(format) ?? "",
                todo.note ?? ""
            ]
            .map(escape)
            .joined(separator: ",")
        }

        return ([header.joined(separator: ",")] + rows).joined(separator: "\n")
    }

    /// Spelled out rather than exported as the stored Int16, so the file reads on its own.
    static func name(_ priority: TodoPriority) -> String {
        switch priority {
        case .none: ""
        case .low: "low"
        case .medium: "medium"
        case .high: "high"
        }
    }

    /// ISO 8601, so a spreadsheet in any locale reads the dates the same way.
    static func format(_ date: Date) -> String {
        date.ISO8601Format()
    }

    /// Every field is quoted and its own quotes doubled: a task title may well contain a comma,
    /// a quote or a newline, any of which would otherwise split the row.
    static func escape(_ field: String) -> String {
        "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
