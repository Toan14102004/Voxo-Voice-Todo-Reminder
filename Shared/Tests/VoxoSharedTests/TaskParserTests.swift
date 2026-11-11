//
//  TaskParserTests.swift
//  VoxoSharedTests
//
//  One dictated sentence in, a task with a time / list / priority out.
//

import XCTest
@testable import VoxoShared

final class TaskParserTests: XCTestCase {
    private let calendar = Calendar.current

    /// Wednesday 11/11/2026, 09:00 local.
    private lazy var now: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 11
        components.day = 11
        components.hour = 9
        return calendar.date(from: components)!
    }()

    private func list(_ name: String) -> TodoListDTO {
        TodoListDTO(name: name, colorHex: "1E6FD0", icon: "house", createdAt: now, updatedAt: now)
    }

    private func parse(_ text: String, lists: [TodoListDTO] = []) -> ParsedTask {
        TaskParser.parse(text, lists: lists, now: now, calendar: calendar)
    }

    private func hour(_ date: Date?) -> Int? {
        date.map { calendar.component(.hour, from: $0) }
    }

    private func day(_ date: Date?) -> Int? {
        date.map { calendar.component(.day, from: $0) }
    }

    // MARK: - Time

    func testReadsAVietnameseAfternoonTime() {
        let result = parse("họp sprint lúc 2 giờ chiều")

        XCTAssertEqual(result.title, "họp sprint")
        XCTAssertEqual(hour(result.dueAt), 14)
    }

    func testReadsAnEveningTimeWrittenWithH() {
        let result = parse("gọi mẹ lúc 8h tối")

        XCTAssertEqual(result.title, "gọi mẹ")
        XCTAssertEqual(hour(result.dueAt), 20)
    }

    func testReadsTomorrow() {
        let result = parse("mua sữa ngày mai")

        XCTAssertEqual(result.title, "mua sữa")
        XCTAssertEqual(day(result.dueAt), 12)
    }

    func testReadsEnglishToo() {
        let result = parse("call mum at 8pm")

        XCTAssertEqual(result.title, "call mum")
        XCTAssertEqual(hour(result.dueAt), 20)
    }

    func testLeavesTheTitleAloneWhenThereIsNoTime() {
        let result = parse("dọn bàn làm việc")

        XCTAssertEqual(result.title, "dọn bàn làm việc")
        XCTAssertNil(result.dueAt)
        XCTAssertFalse(result.isStructured)
    }

    /// A time that has already gone by today is meant for tomorrow — a reminder in the past
    /// never fires.
    func testRollsAPastTimeToTomorrow() {
        let result = parse("chạy bộ 7h sáng")

        XCTAssertEqual(day(result.dueAt), 12)
        XCTAssertEqual(hour(result.dueAt), 7)
    }

    func testKeepsATimeStillAheadToday() {
        let result = parse("họp lúc 4 giờ chiều")

        XCTAssertEqual(day(result.dueAt), 11)
        XCTAssertEqual(hour(result.dueAt), 16)
    }

    // MARK: - List

    func testAssignsAListNamedInTheSentence() {
        let work = list("Công việc")
        let result = parse("gửi báo giá Công việc", lists: [work, list("Mua sắm")])

        XCTAssertEqual(result.listId, work.id)
        XCTAssertEqual(result.title, "gửi báo giá")
    }

    /// Dictation does not always return the marks, so matching ignores them.
    func testMatchesAListNameWithoutDiacritics() {
        let work = list("Công việc")
        let result = parse("gửi báo giá cong viec", lists: [work])

        XCTAssertEqual(result.listId, work.id)
    }

    func testPrefersTheLongerListName() {
        let short = list("Mua sắm")
        let long = list("Mua sắm gia dụng")
        let result = parse("mua nồi Mua sắm gia dụng", lists: [short, long])

        XCTAssertEqual(result.listId, long.id)
    }

    func testLeavesTheListEmptyWhenNoNameMatches() {
        let result = parse("gửi báo giá", lists: [list("Công việc")])

        XCTAssertNil(result.listId)
    }

    // MARK: - Priority

    func testMarksUrgentSentencesHigh() {
        XCTAssertEqual(parse("nộp hồ sơ gấp").priority, .high)
        XCTAssertEqual(parse("việc này quan trọng").priority, .high)
        XCTAssertEqual(parse("send the deck asap").priority, .high)
    }

    func testLeavesPriorityAloneOtherwise() {
        XCTAssertEqual(parse("tưới cây").priority, .none)
    }

    // MARK: - Title clean-up

    func testStripsTheDanglingConnective() {
        XCTAssertEqual(parse("họp lúc 2 giờ chiều").title, "họp")
        XCTAssertEqual(parse("meeting at 8pm").title, "meeting")
    }

    func testReadsEverythingAtOnce() {
        let work = list("Công việc")
        let result = parse("họp sprint review lúc 10 giờ sáng Công việc gấp", lists: [work])

        XCTAssertEqual(result.title, "họp sprint review")
        XCTAssertEqual(hour(result.dueAt), 10)
        XCTAssertEqual(result.listId, work.id)
        XCTAssertEqual(result.priority, .high)
        XCTAssertTrue(result.isStructured)
    }

    /// Nothing left after the recognised parts are removed — keep the sentence rather than
    /// storing a blank task.
    func testFallsBackToTheWholeSentenceWhenNothingIsLeft() {
        let result = parse("ngày mai")

        XCTAssertEqual(result.title, "ngày mai")
        XCTAssertNotNil(result.dueAt)
    }

    func testHandlesAnEmptySentence() {
        XCTAssertEqual(parse("   ").title, "")
    }

    func testRemembersWhatItConsumed() {
        let result = parse("gọi mẹ lúc 8h tối")

        XCTAssertTrue(result.recognised.contains { $0.localizedCaseInsensitiveContains("8h tối") })
    }
}
