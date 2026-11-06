//
//  Entities.swift
//  VoxoShared
//
//  Hand-written NSManagedObject subclasses (codegen is Manual/None in VoxoModel.xcdatamodeld).
//  PLAN.md §11: never rename or delete these without planning a Core Data migration.
//

import CoreData
import Foundation

@objc(TodoEntity)
public final class TodoEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var isDone: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var completedAt: Date?
    @NSManaged public var deletedAt: Date?
    @NSManaged public var intervalOverride: Int32
    @NSManaged public var nextRemindAt: Date?
    @NSManaged public var lastRemindedAt: Date?
    @NSManaged public var originDevice: String

    public static func fetchRequest() -> NSFetchRequest<TodoEntity> {
        NSFetchRequest<TodoEntity>(entityName: "Todo")
    }
}

@objc(SyncOpEntity)
public final class SyncOpEntity: NSManagedObject {
    @NSManaged public var opId: UUID
    @NSManaged public var todoId: UUID
    @NSManaged public var type: String
    @NSManaged public var payload: Data
    @NSManaged public var createdAt: Date

    public static func fetchRequest() -> NSFetchRequest<SyncOpEntity> {
        NSFetchRequest<SyncOpEntity>(entityName: "SyncOp")
    }
}

/// Dedupe ledger for ops the phone has already applied.
///
/// NOT in PLAN.md §4, but §6.3 requires "nếu opId đã xử lý thì bỏ qua", and that needs durable
/// storage — an in-memory set would let a relaunch double-apply every unacknowledged op.
@objc(ProcessedOpEntity)
public final class ProcessedOpEntity: NSManagedObject {
    @NSManaged public var opId: UUID
    @NSManaged public var processedAt: Date

    public static func fetchRequest() -> NSFetchRequest<ProcessedOpEntity> {
        NSFetchRequest<ProcessedOpEntity>(entityName: "ProcessedOp")
    }
}

// MARK: - Mapping

public extension TodoEntity {
    func apply(_ dto: TodoDTO) {
        id = dto.id
        title = dto.title
        isDone = dto.isDone
        createdAt = dto.createdAt
        updatedAt = dto.updatedAt
        completedAt = dto.completedAt
        deletedAt = dto.deletedAt
        intervalOverride = dto.intervalOverride
        nextRemindAt = dto.nextRemindAt
        lastRemindedAt = dto.lastRemindedAt
        originDevice = dto.originDevice.rawValue
    }

    var dto: TodoDTO {
        TodoDTO(
            id: id,
            title: title,
            isDone: isDone,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
            deletedAt: deletedAt,
            intervalOverride: intervalOverride,
            nextRemindAt: nextRemindAt,
            lastRemindedAt: lastRemindedAt,
            originDevice: DeviceRole(rawValue: originDevice) ?? .phone
        )
    }
}

public extension SyncOpEntity {
    func apply(_ dto: SyncOpDTO) {
        opId = dto.opId
        todoId = dto.todoId
        type = dto.type.rawValue
        payload = dto.payload
        createdAt = dto.createdAt
    }

    var dto: SyncOpDTO? {
        guard let opType = SyncOpType(rawValue: type) else { return nil }
        return SyncOpDTO(opId: opId, todoId: todoId, type: opType, payload: payload, createdAt: createdAt)
    }
}
