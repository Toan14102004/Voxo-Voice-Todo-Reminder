//
//  TodoCSV.swift
//  VoiceTodo
//
//  "Xuất dữ liệu · CSV" on the Settings screen. The rows themselves are built by
//  `CSVExport` in VoxoShared; this is only the share-sheet wrapper.
//

import CoreTransferable
import Foundation
import UniformTypeIdentifiers
import VoxoShared

/// The whole task list as a CSV file.
///
/// `Transferable` rather than a pre-written file: the rows are only built when the share sheet
/// actually asks for them, so opening Settings costs nothing.
struct TodoCSV: Transferable {
    let todos: [TodoDTO]
    let lists: [TodoListDTO]

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { csv in
            Data(CSVExport.text(todos: csv.todos, lists: csv.lists).utf8)
        }
        .suggestedFileName("tidy-tasks.csv")
    }
}
