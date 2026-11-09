//
//  ListTests.swift
//  VoxoSharedTests
//
//  PLAN.md §4: the TodoList entity, and what deleting a list does to the todos in it.
//

import XCTest
@testable import VoxoShared

final class ListTests: XCTestCase {
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

    private func repository(_ device: DeviceRole = .phone) -> CoreDataTodoRepository {
        CoreDataTodoRepository(stack: stack, device: device)
    }

    func testCreateAndReadLists() throws {
        let repo = repository()
        let work = try repo.createList(name: "Công việc", colorHex: "1E6FD0", now: t0)
        _ = try repo.createList(name: "Cá nhân", colorHex: "16A34A", now: t0.addingTimeInterval(1))

        let lists = try repo.lists()
        XCTAssertEqual(lists.count, 2)
        XCTAssertEqual(lists.first?.id, work.id)
        XCTAssertEqual(lists.first?.colorHex, "1E6FD0")
    }

    func testListNameIsTrimmedAndRequired() throws {
        let repo = repository()
        let padded = try repo.createList(name: "   Mua sắm   ", colorHex: "F59E0B", now: t0)
        XCTAssertEqual(padded.name, "Mua sắm")

        XCTAssertThrowsError(try repo.createList(name: "  ", colorHex: "F59E0B", now: t0)) { error in
            XCTAssertEqual(error as? RepositoryError, .emptyListName)
        }
    }

    func testTodosCanBeFiledUnderAList() throws {
        let repo = repository()
        let list = try repo.createList(name: "Công việc", colorHex: "1E6FD0", now: t0)

        var todo = try repo.create(title: "Nộp báo cáo", intervalOverride: 0, now: t0)
        todo.listId = list.id
        try repo.update(todo, now: t0.addingTimeInterval(1))

        let inList = try repo.todos(inList: list.id)
        XCTAssertEqual(inList.count, 1)
        XCTAssertEqual(inList.first?.title, "Nộp báo cáo")
    }

    /// PLAN.md §4: "Xoá danh sách không xoá todo trong đó."
    func testDeletingAListKeepsItsTodosAndClearsTheirListId() throws {
        let repo = repository()
        let list = try repo.createList(name: "Công việc", colorHex: "1E6FD0", now: t0)

        var todo = try repo.create(title: "Nộp báo cáo", intervalOverride: 0, now: t0)
        todo.listId = list.id
        try repo.update(todo, now: t0.addingTimeInterval(1))

        try repo.deleteList(id: list.id, now: t0.addingTimeInterval(2))

        let survivor = try XCTUnwrap(try repo.todo(id: todo.id))
        XCTAssertFalse(survivor.isDeleted, "việc phải sống sót khi danh sách bị xoá")
        XCTAssertNil(survivor.listId, "việc phải rời khỏi danh sách đã xoá")
        XCTAssertEqual(survivor.updatedAt, t0.addingTimeInterval(2), "updatedAt phải tăng để thắng merge ở máy kia")

        XCTAssertTrue(try repo.lists().isEmpty)
        XCTAssertEqual(try repo.activeTodos().count, 1)
    }

    func testDeletedListIsATombstoneNotARowRemoval() throws {
        let repo = repository()
        let list = try repo.createList(name: "Tạm", colorHex: "A8A29E", now: t0)
        try repo.deleteList(id: list.id, now: t0.addingTimeInterval(5))

        XCTAssertTrue(try repo.lists().isEmpty)
        let stored = try XCTUnwrap(try repo.list(id: list.id))
        XCTAssertEqual(stored.deletedAt, t0.addingTimeInterval(5))
    }

    func testRemoteListFollowsTheSameMergeRules() throws {
        let repo = repository()
        let incoming = TodoListDTO(name: "Từ watch", colorHex: "3B82F6", createdAt: t0, updatedAt: t0)

        XCTAssertNotNil(try repo.apply(remoteList: incoming))

        var stale = incoming
        stale.name = "Bản cũ"
        stale.updatedAt = t0.addingTimeInterval(-10)
        XCTAssertNil(try repo.apply(remoteList: stale))
        XCTAssertEqual(try repo.list(id: incoming.id)?.name, "Từ watch")

        var fresh = incoming
        fresh.name = "Bản mới"
        fresh.updatedAt = t0.addingTimeInterval(10)
        XCTAssertNotNil(try repo.apply(remoteList: fresh))
        XCTAssertEqual(try repo.list(id: incoming.id)?.name, "Bản mới")
    }

    /// A delete arriving from the other device must unfile its todos too, not just tombstone.
    func testRemoteListDeletionAlsoUnfilesTodos() throws {
        let repo = repository()
        let list = try repo.createList(name: "Công việc", colorHex: "1E6FD0", now: t0)

        var todo = try repo.create(title: "Việc A", intervalOverride: 0, now: t0)
        todo.listId = list.id
        try repo.update(todo, now: t0.addingTimeInterval(1))

        var remoteDelete = try XCTUnwrap(try repo.list(id: list.id))
        remoteDelete.deletedAt = t0.addingTimeInterval(9)
        remoteDelete.updatedAt = t0.addingTimeInterval(9)
        try repo.apply(remoteList: remoteDelete)

        XCTAssertNil(try repo.todo(id: todo.id)?.listId)
        XCTAssertEqual(try repo.activeTodos().count, 1)
    }

    func testPriorityAndDueDateRoundTrip() throws {
        let repo = repository()
        var todo = try repo.create(title: "Nộp báo cáo", intervalOverride: 0, now: t0)
        todo.priority = .high
        todo.dueAt = t0.addingTimeInterval(3600)
        todo.repeatRule = .weekly
        try repo.update(todo, now: t0.addingTimeInterval(1))

        let stored = try XCTUnwrap(try repo.todo(id: todo.id))
        XCTAssertEqual(stored.priority, .high)
        XCTAssertEqual(stored.dueAt, t0.addingTimeInterval(3600))
        XCTAssertEqual(stored.repeatRule, .weekly)
    }
}

extension ListTests {
    func testListKeepsItsIcon() throws {
        let repo = repository()
        let list = try repo.createList(name: "Mua sắm", colorHex: "16A34A", icon: "cart", now: t0)
        XCTAssertEqual(try repo.list(id: list.id)?.icon, "cart")
    }

    /// The grid counts unfinished tasks only; a finished one must not keep inflating the badge.
    func testCompletedTasksLeaveTheListCount() throws {
        let repo = repository()
        let list = try repo.createList(name: "Công việc", colorHex: "F59E0B", icon: "briefcase", now: t0)

        var todo = try repo.create(title: "Nộp báo cáo", intervalOverride: 0, now: t0)
        todo.listId = list.id
        try repo.update(todo, now: t0.addingTimeInterval(1))
        XCTAssertEqual(try repo.todos(inList: list.id).count, 1)

        try repo.complete(id: todo.id, now: t0.addingTimeInterval(2))
        XCTAssertEqual(try repo.todos(inList: list.id).filter { !$0.isDone }.count, 0)
    }
}
