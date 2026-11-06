//
//  SchedulerTests.swift
//  VoxoSharedTests
//
//  PLAN.md §8 Phase 2, adapted to the aggregated reminders of §1.7.
//

import XCTest
@testable import VoxoShared

final class SchedulerTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    private func todo(
        _ title: String,
        createdOffset: TimeInterval = 0,
        interval: Int32 = 0,
        isDone: Bool = false,
        deleted: Bool = false
    ) -> TodoDTO {
        TodoDTO(
            title: title,
            isDone: isDone,
            createdAt: t0.addingTimeInterval(createdOffset),
            updatedAt: t0,
            deletedAt: deleted ? t0 : nil,
            intervalOverride: interval,
            originDevice: .phone
        )
    }

    func testNoTodosMeansNoNotifications() {
        XCTAssertTrue(ReminderScheduler.plan(todos: []).isEmpty)
    }

    func testSharedCycleTodosCollapseIntoOnePlan() {
        let plans = ReminderScheduler.plan(
            todos: [todo("A", createdOffset: 0), todo("B", createdOffset: 10), todo("C", createdOffset: 20)],
            globalIntervalMinutes: 120
        )

        XCTAssertEqual(plans.count, 1, "ba việc chung chu kỳ chỉ được dùng một slot")
        let plan = try! XCTUnwrap(plans.first)
        XCTAssertEqual(plan.id, ReminderPlan.sharedIdentifier)
        XCTAssertEqual(plan.kind, .shared(todoCount: 3))
        XCTAssertEqual(plan.intervalMinutes, 120)
    }

    /// PLAN.md §1.7: the notification names the oldest unfinished todo.
    func testSharedPlanNamesTheOldestTodo() {
        let plans = ReminderScheduler.plan(todos: [
            todo("Mới nhất", createdOffset: 100),
            todo("Cũ nhất", createdOffset: 0),
            todo("Ở giữa", createdOffset: 50)
        ])

        XCTAssertEqual(plans.first?.body, "Cũ nhất — and 2 others")
    }

    func testSingleTodoHasNoOthersSuffix() {
        let plans = ReminderScheduler.plan(todos: [todo("Đổ rác")])
        XCTAssertEqual(plans.first?.body, "Đổ rác")
    }

    func testTwoTodosSayOneOtherNotOneOthers() {
        let plans = ReminderScheduler.plan(todos: [todo("A", createdOffset: 0), todo("B", createdOffset: 1)])
        XCTAssertEqual(plans.first?.body, "A — and 1 other")
    }

    func testCustomCycleTodoGetsItsOwnPlanAndLeavesTheSharedCount() {
        let plans = ReminderScheduler.plan(
            todos: [
                todo("Chung 1", createdOffset: 0),
                todo("Chung 2", createdOffset: 10),
                todo("Riêng", createdOffset: 20, interval: 1440)
            ],
            globalIntervalMinutes: 60
        )

        XCTAssertEqual(plans.count, 2)

        let shared = try! XCTUnwrap(plans.first { $0.id == ReminderPlan.sharedIdentifier })
        XCTAssertEqual(shared.kind, .shared(todoCount: 2), "việc có chu kỳ riêng không được đếm vào nhóm chung")
        XCTAssertEqual(shared.intervalMinutes, 60)

        let single = try! XCTUnwrap(plans.first { $0.kind == .single })
        XCTAssertEqual(single.body, "Riêng")
        XCTAssertEqual(single.intervalMinutes, 1440)
    }

    func testFinishedTodosAreExcluded() {
        let plans = ReminderScheduler.plan(todos: [
            todo("Xong rồi", createdOffset: 0, isDone: true),
            todo("Còn lại", createdOffset: 10)
        ])

        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans.first?.body, "Còn lại")
    }

    func testDeletedTodosAreExcluded() {
        let plans = ReminderScheduler.plan(todos: [
            todo("Đã xoá", createdOffset: 0, deleted: true),
            todo("Còn lại", createdOffset: 10)
        ])

        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans.first?.body, "Còn lại")
    }

    /// A finished todo must not keep its custom-cycle notification alive.
    func testFinishingACustomCycleTodoRemovesItsPlan() {
        let plans = ReminderScheduler.plan(todos: [
            todo("Riêng xong", interval: 180, isDone: true)
        ])
        XCTAssertTrue(plans.isEmpty)
    }

    /// Everything done means silence, not a notification saying zero.
    func testAllFinishedMeansNoPlans() {
        let plans = ReminderScheduler.plan(todos: [
            todo("A", isDone: true),
            todo("B", deleted: true)
        ])
        XCTAssertTrue(plans.isEmpty)
    }

    /// Slot budget is the whole reason for §1.7.
    func testSlotCountStaysSmallWithManyTodos() {
        let many = (0..<50).map { todo("Việc \($0)", createdOffset: TimeInterval($0)) }
        let withCustom = many + [todo("Riêng", createdOffset: 999, interval: 720)]

        XCTAssertEqual(ReminderScheduler.plan(todos: many).count, 1)
        XCTAssertEqual(ReminderScheduler.plan(todos: withCustom).count, 2)
    }

    func testOrderIsStableWhenCreatedAtCollides() {
        let a = todo("A")
        let b = todo("B")
        let first = ReminderScheduler.plan(todos: [a, b]).first?.todoId
        let second = ReminderScheduler.plan(todos: [b, a]).first?.todoId
        XCTAssertEqual(first, second, "cùng mốc thời gian thì vẫn phải chọn ra cùng một việc")
    }
}
