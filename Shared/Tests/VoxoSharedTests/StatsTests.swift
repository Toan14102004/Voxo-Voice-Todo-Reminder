//
//  StatsTests.swift
//  VoxoSharedTests
//
//  The Stats tab's arithmetic: what belongs to a week, the streak, and the week-over-week delta.
//

import XCTest
@testable import VoxoShared

final class StatsTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Monday 2026-11-09 00:00 UTC.
    private let monday = Date(timeIntervalSince1970: 1_794_441_600)

    private func day(_ offset: Int, hour: Int = 9) -> Date {
        monday.addingTimeInterval(TimeInterval(offset) * 86_400 + TimeInterval(hour) * 3600)
    }

    private func done(_ title: String, on date: Date, list: UUID? = nil) -> TodoDTO {
        TodoDTO(
            title: title,
            isDone: true,
            createdAt: date.addingTimeInterval(-3600),
            updatedAt: date,
            completedAt: date,
            originDevice: .phone,
            listId: list
        )
    }

    private func open(_ title: String, createdAt: Date, list: UUID? = nil) -> TodoDTO {
        TodoDTO(
            title: title,
            createdAt: createdAt,
            updatedAt: createdAt,
            originDevice: .phone,
            listId: list
        )
    }

    private func list(_ name: String) -> TodoListDTO {
        TodoListDTO(name: name, colorHex: "1E6FD0", icon: "house", createdAt: monday, updatedAt: monday)
    }

    private func stats(_ todos: [TodoDTO], lists: [TodoListDTO] = [], now: Date) -> WeekStats {
        StatsCalculator.stats(
            todos: todos,
            lists: lists,
            weekStart: monday,
            now: now,
            calendar: calendar
        )
    }

    // MARK: - Per day

    func testCountsCompletionsOnTheRightDay() {
        let result = stats(
            [done("a", on: day(0)), done("b", on: day(0, hour: 22)), done("c", on: day(3))],
            now: day(4)
        )

        XCTAssertEqual(result.perDay, [2, 0, 0, 1, 0, 0, 0])
        XCTAssertEqual(result.completedTotal, 3)
    }

    func testIgnoresCompletionsOutsideTheWeek() {
        let result = stats(
            [done("last week", on: day(-2)), done("next week", on: day(8)), done("inside", on: day(1))],
            now: day(2)
        )

        XCTAssertEqual(result.completedTotal, 1)
        XCTAssertEqual(result.perDay, [0, 1, 0, 0, 0, 0, 0])
    }

    // MARK: - Completion rate

    func testRateCountsCompletedAgainstOpenWorkCreatedTheSameWeek() {
        let result = stats(
            [done("a", on: day(0)), done("b", on: day(1)), open("c", createdAt: day(2))],
            now: day(3)
        )

        XCTAssertEqual(result.completionRate, 2.0 / 3.0, accuracy: 0.0001)
    }

    /// An untouched task from an earlier week must not drag this week's rate down forever.
    func testRateIgnoresOpenWorkCarriedOverFromAnEarlierWeek() {
        let result = stats(
            [done("a", on: day(0)), open("old", createdAt: day(-10))],
            now: day(1)
        )

        XCTAssertEqual(result.completionRate, 1.0, accuracy: 0.0001)
    }

    func testRateIsZeroWhenTheWeekIsEmpty() {
        XCTAssertEqual(stats([], now: day(1)).completionRate, 0)
    }

    // MARK: - Streak

    func testStreakCountsConsecutiveDaysBackFromToday() {
        let result = stats(
            [done("a", on: day(0)), done("b", on: day(1)), done("c", on: day(2))],
            now: day(2, hour: 20)
        )

        XCTAssertEqual(result.streak, 3)
    }

    func testStreakBreaksOnAMissedDay() {
        let result = stats(
            [done("a", on: day(0)), done("c", on: day(2)), done("d", on: day(3))],
            now: day(3, hour: 20)
        )

        XCTAssertEqual(result.streak, 2)
    }

    /// Before the first task of the day is ticked, the streak counts back from yesterday rather
    /// than collapsing to zero.
    func testStreakSurvivesAMorningWithNothingDoneYet() {
        let result = stats(
            [done("a", on: day(0)), done("b", on: day(1))],
            now: day(2, hour: 7)
        )

        XCTAssertEqual(result.streak, 2)
    }

    func testStreakIsZeroWithoutAnyCompletion() {
        XCTAssertEqual(stats([open("a", createdAt: day(0))], now: day(1)).streak, 0)
    }

    // MARK: - Comparison with the previous week

    func testDeltaComparesWithThePrecedingWeek() {
        let result = stats(
            [
                done("a", on: day(0)), done("b", on: day(1)), done("c", on: day(2)),
                done("old1", on: day(-7)), done("old2", on: day(-5))
            ],
            now: day(3)
        )

        XCTAssertEqual(result.deltaVsPreviousWeek, 1)
    }

    func testDeltaIsNegativeWhenTheWeekIsWorse() {
        let result = stats([done("old", on: day(-7)), done("old2", on: day(-6))], now: day(3))

        XCTAssertEqual(result.deltaVsPreviousWeek, -2)
    }

    // MARK: - Per list

    func testPerListSplitsDoneAndTotal() {
        let work = list("Work")
        let home = list("Home")

        let result = stats(
            [
                done("a", on: day(0), list: work.id),
                done("b", on: day(1), list: work.id),
                open("c", createdAt: day(1), list: work.id),
                done("d", on: day(2), list: home.id)
            ],
            lists: [work, home],
            now: day(3)
        )

        XCTAssertEqual(result.byList.count, 2)
        XCTAssertEqual(result.byList[0].done, 2)
        XCTAssertEqual(result.byList[0].total, 3)
        XCTAssertEqual(result.byList[1].done, 1)
        XCTAssertEqual(result.byList[1].total, 1)
    }

    /// A list with nothing in it this week is left out rather than drawn as an empty bar.
    func testPerListSkipsListsWithNothingThisWeek() {
        let idle = list("Idle")
        let result = stats([done("a", on: day(0))], lists: [idle], now: day(1))

        XCTAssertTrue(result.byList.isEmpty)
    }
}
