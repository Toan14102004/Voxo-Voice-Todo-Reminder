//
//  CSVExportTests.swift
//  VoxoSharedTests
//
//  Settings → "Xuất dữ liệu". A task title is free text, so the escaping has to hold.
//

import XCTest
@testable import VoxoShared

final class CSVExportTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    private func todo(
        _ title: String,
        isDone: Bool = false,
        priority: TodoPriority = .none,
        listId: UUID? = nil,
        note: String? = nil
    ) -> TodoDTO {
        TodoDTO(
            title: title,
            isDone: isDone,
            createdAt: t0,
            updatedAt: t0,
            completedAt: isDone ? t0 : nil,
            originDevice: .phone,
            priority: priority,
            listId: listId,
            note: note
        )
    }

    private func rows(_ text: String) -> [String] {
        text.components(separatedBy: "\n")
    }

    func testStartsWithTheHeaderRow() {
        let text = CSVExport.text(todos: [], lists: [])

        XCTAssertEqual(rows(text).count, 1)
        XCTAssertEqual(rows(text)[0], CSVExport.header.joined(separator: ","))
    }

    func testOneRowPerTodo() {
        let text = CSVExport.text(todos: [todo("a"), todo("b"), todo("c")], lists: [])

        XCTAssertEqual(rows(text).count, 4)
    }

    func testWritesStatusAndPriority() {
        let text = CSVExport.text(todos: [todo("Pay bill", isDone: true, priority: .high)], lists: [])

        XCTAssertTrue(rows(text)[1].hasPrefix("\"Pay bill\",\"done\",\"high\""))
    }

    func testResolvesTheListName() {
        let list = TodoListDTO(name: "Công việc", colorHex: "F59E0B", icon: "briefcase",
                               createdAt: t0, updatedAt: t0)
        let text = CSVExport.text(todos: [todo("x", listId: list.id)], lists: [list])

        XCTAssertTrue(rows(text)[1].contains("\"Công việc\""))
    }

    func testLeavesTheListEmptyWhenTheTodoHasNone() {
        let text = CSVExport.text(todos: [todo("x")], lists: [])

        XCTAssertTrue(rows(text)[1].contains("\"open\",\"\",\"\","))
    }

    /// A comma in a title must not split the row.
    func testQuotesACommaInsideAField() {
        let text = CSVExport.text(todos: [todo("Buy milk, eggs")], lists: [])

        XCTAssertTrue(rows(text)[1].hasPrefix("\"Buy milk, eggs\""))
    }

    /// A quote is doubled, which is how CSV escapes it.
    func testDoublesAQuoteInsideAField() {
        let text = CSVExport.text(todos: [todo("Read \"Dune\"")], lists: [])

        XCTAssertTrue(rows(text)[1].hasPrefix("\"Read \"\"Dune\"\"\""))
    }

    func testKeepsANewlineInsideTheQuotedField() {
        let text = CSVExport.text(todos: [todo("x", note: "line 1\nline 2")], lists: [])

        XCTAssertTrue(text.contains("\"line 1\nline 2\""))
    }
}
