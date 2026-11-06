//
//  OutboxTests.swift
//  VoxoSharedTests
//
//  The Watch outbox and the phone's dedupe ledger (PLAN.md §6).
//

import XCTest
@testable import VoxoShared

final class OutboxTests: XCTestCase {
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

    /// PLAN.md §6.1: the op is written in the same transaction as the todo change.
    func testEveryLocalChangeOnTheWatchQueuesAnOp() throws {
        let repo = repository(.watch)
        let todo = try repo.create(title: "Mua sữa", intervalOverride: 0, now: t0)
        try repo.complete(id: todo.id, now: t0.addingTimeInterval(1))
        try repo.delete(id: todo.id, now: t0.addingTimeInterval(2))

        let ops = try repo.pendingOps()
        XCTAssertEqual(ops.map(\.type), [.create, .complete, .delete])
        XCTAssertEqual(ops.map(\.todoId), [todo.id, todo.id, todo.id])
        // Ordered by createdAt so the phone replays them in the order they happened.
        XCTAssertEqual(ops.map(\.createdAt), ops.map(\.createdAt).sorted())
    }

    func testOpCarriesTheTodoItDescribes() throws {
        let repo = repository(.watch)
        let todo = try repo.create(title: "Gọi điện cho mẹ", intervalOverride: 120, now: t0)

        let op = try XCTUnwrap(try repo.pendingOps().first)
        let decoded = try op.decodeTodo()
        XCTAssertEqual(decoded.id, todo.id)
        XCTAssertEqual(decoded.title, "Gọi điện cho mẹ")
        XCTAssertEqual(decoded.intervalOverride, 120)
        XCTAssertEqual(decoded.originDevice, .watch)
    }

    func testThePhoneQueuesNothing() throws {
        let repo = repository(.phone)
        let todo = try repo.create(title: "Trên máy chính", intervalOverride: 0, now: t0)
        try repo.complete(id: todo.id, now: t0.addingTimeInterval(1))

        XCTAssertEqual(try repo.pendingOpCount(), 0)
    }

    func testAckRemovesOnlyAcknowledgedOps() throws {
        let repo = repository(.watch)
        let first = try repo.create(title: "Một", intervalOverride: 0, now: t0)
        _ = try repo.create(title: "Hai", intervalOverride: 0, now: t0.addingTimeInterval(1))

        let ops = try repo.pendingOps()
        XCTAssertEqual(ops.count, 2)
        let firstOp = try XCTUnwrap(ops.first { $0.todoId == first.id })

        XCTAssertEqual(try repo.acknowledge(opIds: [firstOp.opId]), 1)

        let remaining = try repo.pendingOps()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertNotEqual(remaining.first?.opId, firstOp.opId)
    }

    /// PLAN.md §6.6: without an ACK the op stays put, so a dropped transfer is retried.
    func testUnacknowledgedOpsSurvive() throws {
        let repo = repository(.watch)
        _ = try repo.create(title: "Chưa ACK", intervalOverride: 0, now: t0)

        XCTAssertEqual(try repo.acknowledge(opIds: []), 0)
        XCTAssertEqual(try repo.acknowledge(opIds: [UUID()]), 0)
        XCTAssertEqual(try repo.pendingOpCount(), 1)
    }

    /// PLAN.md §6.3: a replayed opId must not be applied twice.
    func testProcessedLogRejectsDuplicateOpIds() throws {
        let repo = repository(.phone)
        let opId = UUID()

        XCTAssertFalse(try repo.hasProcessed(opId: opId))
        XCTAssertTrue(try repo.markProcessed(opId: opId, now: t0))
        XCTAssertTrue(try repo.hasProcessed(opId: opId))
        // Second delivery of the same op is a no-op.
        XCTAssertFalse(try repo.markProcessed(opId: opId, now: t0.addingTimeInterval(60)))
        XCTAssertFalse(try repo.hasProcessed(opId: UUID()))
    }

    /// End-to-end of the §6 loop: watch queues, phone dedupes and applies, watch drops on ACK.
    func testWatchToPhoneRoundTrip() throws {
        let watchStack = PersistenceStack(inMemory: true)
        let phoneStack = PersistenceStack(inMemory: true)
        let watch = CoreDataTodoRepository(stack: watchStack, device: .watch)
        let phone = CoreDataTodoRepository(stack: phoneStack, device: .phone)

        _ = try watch.create(title: "Đổ rác", intervalOverride: 0, now: t0)
        let ops = try watch.pendingOps()
        XCTAssertEqual(ops.count, 1)

        // Phone receives the same op twice (transferUserInfo can redeliver).
        for op in ops + ops {
            guard try phone.markProcessed(opId: op.opId, now: t0) else { continue }
            try phone.apply(remote: op.decodeTodo())
        }
        XCTAssertEqual(try phone.activeTodos().count, 1, "op lặp lại không được tạo bản ghi thứ hai")

        // Phone acks; watch clears its outbox.
        XCTAssertEqual(try watch.acknowledge(opIds: ops.map(\.opId)), 1)
        XCTAssertEqual(try watch.pendingOpCount(), 0)
    }
}
