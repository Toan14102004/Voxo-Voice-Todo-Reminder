//
//  RepositoryTests.swift
//  VoxoSharedTests
//
//  In-memory store, per PLAN.md §8 Phase 3.
//

import XCTest
@testable import VoxoShared

final class RepositoryTests: XCTestCase {
    private var stack: PersistenceStack!
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUp() {
        super.setUp()
        stack = PersistenceStack(inMemory: true)
    }

    override func tearDown() {
        stack = nil
        super.tearDown()
    }

    private func repository(_ device: DeviceRole) -> CoreDataTodoRepository {
        CoreDataTodoRepository(stack: stack, device: device)
    }

    func testCreateThenRead() throws {
        let repo = repository(.phone)
        let created = try repo.create(title: "Mua sữa cho con", intervalOverride: 0, now: t0)

        let active = try repo.activeTodos()
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first?.id, created.id)
        XCTAssertEqual(active.first?.title, "Mua sữa cho con")
        XCTAssertEqual(active.first?.originDevice, .phone)
        XCTAssertEqual(active.first?.intervalOverride, 0)
    }

    func testTitleIsTrimmedAndCapped() throws {
        let repo = repository(.phone)

        let padded = try repo.create(title: "   Đổ rác   ", intervalOverride: 0, now: t0)
        XCTAssertEqual(padded.title, "Đổ rác")

        let long = try repo.create(title: String(repeating: "a", count: 500), intervalOverride: 0, now: t0)
        XCTAssertEqual(long.title.count, TodoDTO.maxTitleLength)

        XCTAssertThrowsError(try repo.create(title: "   ", intervalOverride: 0, now: t0)) { error in
            XCTAssertEqual(error as? RepositoryError, .emptyTitle)
        }
    }

    func testCompleteMovesItOutOfActiveAndStopsReminders() throws {
        let repo = repository(.phone)
        let todo = try repo.create(title: "Uống thuốc", intervalOverride: 0, now: t0)
        let later = t0.addingTimeInterval(60)

        try repo.complete(id: todo.id, now: later)

        XCTAssertTrue(try repo.activeTodos().isEmpty)
        let done = try XCTUnwrap(try repo.completedTodos().first)
        XCTAssertTrue(done.isDone)
        XCTAssertEqual(done.completedAt, later)
        XCTAssertEqual(done.updatedAt, later)
        XCTAssertNil(done.nextRemindAt)
    }

    func testDeleteIsATombstoneNotARowRemoval() throws {
        let repo = repository(.phone)
        let todo = try repo.create(title: "Đặt vé máy bay", intervalOverride: 0, now: t0)
        let later = t0.addingTimeInterval(60)

        try repo.delete(id: todo.id, now: later)

        XCTAssertTrue(try repo.activeTodos().isEmpty)
        XCTAssertTrue(try repo.completedTodos().isEmpty)
        let stored = try XCTUnwrap(try repo.todo(id: todo.id))
        XCTAssertEqual(stored.deletedAt, later)
    }

    func testPurgeDropsOnlyTombstonesPastThirtyDays() throws {
        let repo = repository(.phone)
        let old = try repo.create(title: "Cũ", intervalOverride: 0, now: t0)
        let recent = try repo.create(title: "Mới", intervalOverride: 0, now: t0)
        let alive = try repo.create(title: "Còn sống", intervalOverride: 0, now: t0)

        try repo.delete(id: old.id, now: t0)
        try repo.delete(id: recent.id, now: t0.addingTimeInterval(MergeService.tombstoneRetention))

        let now = t0.addingTimeInterval(MergeService.tombstoneRetention + 1)
        let purged = try repo.purgeTombstones(olderThan: MergeService.tombstoneRetention, now: now)

        XCTAssertEqual(purged, 1)
        XCTAssertNil(try repo.todo(id: old.id))
        XCTAssertNotNil(try repo.todo(id: recent.id))
        XCTAssertNotNil(try repo.todo(id: alive.id))
    }

    func testUpdateRejectsUnknownTodo() throws {
        let repo = repository(.phone)
        let ghost = TodoDTO(title: "Không tồn tại", createdAt: t0, updatedAt: t0, originDevice: .phone)

        XCTAssertThrowsError(try repo.update(ghost, now: t0)) { error in
            XCTAssertEqual(error as? RepositoryError, .notFound(ghost.id))
        }
    }

    func testApplyRemoteInsertsAndRespectsMergeRules() throws {
        let repo = repository(.phone)
        let incoming = TodoDTO(title: "Từ watch", createdAt: t0, updatedAt: t0, originDevice: .watch)

        XCTAssertNotNil(try repo.apply(remote: incoming))
        XCTAssertEqual(try repo.activeTodos().count, 1)

        // Stale version loses and writes nothing.
        var stale = incoming
        stale.title = "Bản cũ"
        stale.updatedAt = t0.addingTimeInterval(-10)
        XCTAssertNil(try repo.apply(remote: stale))
        XCTAssertEqual(try repo.todo(id: incoming.id)?.title, "Từ watch")

        // Newer version wins.
        var fresh = incoming
        fresh.title = "Bản mới"
        fresh.updatedAt = t0.addingTimeInterval(10)
        XCTAssertNotNil(try repo.apply(remote: fresh))
        XCTAssertEqual(try repo.todo(id: incoming.id)?.title, "Bản mới")
    }

    /// PLAN.md §6: applying a remote change must not generate an outbound op, or the two devices
    /// would ping-pong the same edit forever.
    func testApplyingRemoteChangesWritesNoSyncOp() throws {
        let repo = repository(.watch)
        let incoming = TodoDTO(title: "Từ phone", createdAt: t0, updatedAt: t0, originDevice: .phone)

        try repo.apply(remote: incoming)

        XCTAssertEqual(try repo.pendingOpCount(), 0)
    }
}

extension RepositoryTests {
    /// Several todos created in the same instant must still come back in a stable order.
    func testOrderIsStableWhenTimestampsCollide() throws {
        let repo = repository(.phone)
        for index in 0..<8 {
            _ = try repo.create(title: "Task \(index)", intervalOverride: 0, now: t0)
        }

        let first = try repo.activeTodos().map(\.id)
        let second = try repo.activeTodos().map(\.id)
        XCTAssertEqual(first, second)
        XCTAssertEqual(first, first.sorted { $0.uuidString < $1.uuidString })
    }
}

extension RepositoryTests {
    /// Ticking a done task must bring it back, not complete it a second time.
    func testReopenUndoesACompletion() throws {
        let repo = repository(.phone)
        let todo = try repo.create(title: "Đổ rác", intervalOverride: 0, now: t0)
        try repo.complete(id: todo.id, now: t0.addingTimeInterval(60))

        XCTAssertTrue(try repo.activeTodos().isEmpty)

        try repo.reopen(id: todo.id, now: t0.addingTimeInterval(120))

        let reopened = try XCTUnwrap(try repo.todo(id: todo.id))
        XCTAssertFalse(reopened.isDone)
        XCTAssertNil(reopened.completedAt, "giờ hoàn thành cũ phải bị xoá, nếu không dòng meta hiện sai")
        XCTAssertEqual(reopened.updatedAt, t0.addingTimeInterval(120))
        XCTAssertEqual(try repo.activeTodos().count, 1)
        XCTAssertTrue(try repo.completedTodos().isEmpty)
    }

    /// Reopening on the Watch must travel like any other change.
    func testReopenQueuesASyncOpOnTheWatch() throws {
        let repo = repository(.watch)
        let todo = try repo.create(title: "Việc", intervalOverride: 0, now: t0)
        try repo.complete(id: todo.id, now: t0.addingTimeInterval(1))
        try repo.reopen(id: todo.id, now: t0.addingTimeInterval(2))

        XCTAssertEqual(try repo.pendingOps().map(\.type), [.create, .complete, .update])
    }
}
