//
//  MigrationTests.swift
//  VoxoSharedTests
//
//  PLAN.md §8 Giai đoạn B: migrating a version 1 store onto version 2 must keep the data.
//

import CoreData
import XCTest
@testable import VoxoShared

final class MigrationTests: XCTestCase {
    private var directory: URL!
    private var storeURL: URL!
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("voxo-migration-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        storeURL = directory.appendingPathComponent("VoxoModel.sqlite")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        try super.tearDownWithError()
    }

    /// Writes one todo using the frozen version 1 model.
    @discardableResult
    private func seedVersion1(title: String) throws -> UUID {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: VoxoModel.version1)
        try coordinator.addPersistentStore(type: .sqlite, at: storeURL)

        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        let id = UUID()
        let todo: TodoEntity = context.insertEntity("Todo")
        todo.id = id
        todo.title = title
        todo.isDone = false
        todo.createdAt = t0
        todo.updatedAt = t0
        todo.intervalOverride = 120
        todo.originDevice = DeviceRole.watch.rawValue
        try context.save()

        for store in coordinator.persistentStores {
            try coordinator.remove(store)
        }
        return id
    }

    func testVersion1StoreIsNotReadableByVersion2() throws {
        try seedVersion1(title: "Cũ")

        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(type: .sqlite, at: storeURL)
        XCTAssertTrue(VoxoModel.version1.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata))
        XCTAssertFalse(
            VoxoModel.version2.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata),
            "nếu v2 đọc được store v1 thì bài test di trú không chứng minh được gì"
        )
    }

    func testMigrationKeepsExistingTodos() throws {
        let id = try seedVersion1(title: "Mua sữa")

        try StoreMigrator.migrateIfNeeded(storeURL: storeURL)

        let stack = PersistenceStack(storeURL: storeURL)
        let repo = CoreDataTodoRepository(stack: stack, device: .phone)
        let migrated = try XCTUnwrap(try repo.todo(id: id))

        XCTAssertEqual(migrated.title, "Mua sữa")
        XCTAssertEqual(migrated.intervalOverride, 120)
        XCTAssertEqual(migrated.originDevice, .watch)
    }

    /// New columns must come back as their defaults, not as garbage.
    func testMigratedTodosGetDefaultsForTheNewFields() throws {
        let id = try seedVersion1(title: "Đổ rác")

        try StoreMigrator.migrateIfNeeded(storeURL: storeURL)

        let stack = PersistenceStack(storeURL: storeURL)
        let repo = CoreDataTodoRepository(stack: stack, device: .phone)
        let migrated = try XCTUnwrap(try repo.todo(id: id))

        XCTAssertEqual(migrated.priority, .none)
        XCTAssertNil(migrated.dueAt)
        XCTAssertNil(migrated.listId)
        XCTAssertNil(migrated.repeatRule)
    }

    func testMigratingAnAlreadyCurrentStoreDoesNothing() throws {
        let id = try seedVersion1(title: "Chạy hai lần")
        try StoreMigrator.migrateIfNeeded(storeURL: storeURL)
        // Second call must be a no-op rather than an error or a data loss.
        try StoreMigrator.migrateIfNeeded(storeURL: storeURL)

        let stack = PersistenceStack(storeURL: storeURL)
        let repo = CoreDataTodoRepository(stack: stack, device: .phone)
        XCTAssertNotNil(try repo.todo(id: id))
    }

    func testMissingStoreIsNotAnError() throws {
        let absent = directory.appendingPathComponent("không-tồn-tại.sqlite")
        XCTAssertNoThrow(try StoreMigrator.migrateIfNeeded(storeURL: absent))
    }
}
