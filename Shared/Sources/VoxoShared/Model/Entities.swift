//
//  Entities.swift
//  VoxoShared
//
//  Hand-written NSManagedObject subclasses (codegen is Manual/None in VoxoModel.xcdatamodeld).
//  PLAN.md §11: never rename or delete these without planning a Core Data migration.
//

import CoreData
import Foundation

public extension NSManagedObjectContext {
    /// Inserts by entity *name* rather than `Entity(context:)`.
    ///
    /// Two model versions declare the same `NSManagedObject` subclasses, so `+[TodoEntity entity]`
    /// has no unique match and silently picks one — which on a v2 store hands back a v1 entity
    /// description with no `priority`, and every write then fails with "unrecognized selector".
    /// Looking the entity up in this context's own model removes the ambiguity.
    func insertEntity<T: NSManagedObject>(_ name: String) -> T {
        guard let description = persistentStoreCoordinator?.managedObjectModel.entitiesByName[name]
            ?? NSEntityDescription.entity(forEntityName: name, in: self) else {
            fatalError("Model đang mở không có entity \(name)")
        }
        return T(entity: description, insertInto: self)
    }
}

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

    // Added in model version 2 (Tidy spec).
    @NSManaged public var priority: Int16
    @NSManaged public var dueAt: Date?
    @NSManaged public var listId: UUID?
    @NSManaged public var repeatRule: String?
    @NSManaged public var note: String?

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

@objc(TodoListEntity)
public final class TodoListEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var colorHex: String
    @NSManaged public var icon: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var deletedAt: Date?

    public static func fetchRequest() -> NSFetchRequest<TodoListEntity> {
        NSFetchRequest<TodoListEntity>(entityName: "TodoList")
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
        priority = dto.priority.rawValue
        dueAt = dto.dueAt
        listId = dto.listId
        repeatRule = dto.repeatRule?.rawValue
        note = dto.note
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
            originDevice: DeviceRole(rawValue: originDevice) ?? .phone,
            priority: TodoPriority(rawValue: priority) ?? .none,
            dueAt: dueAt,
            listId: listId,
            repeatRule: repeatRule.flatMap(RepeatRule.init(rawValue:)),
            note: note
        )
    }
}

public extension TodoListEntity {
    func apply(_ dto: TodoListDTO) {
        id = dto.id
        name = dto.name
        colorHex = dto.colorHex
        icon = dto.icon
        createdAt = dto.createdAt
        updatedAt = dto.updatedAt
        deletedAt = dto.deletedAt
    }

    var dto: TodoListDTO {
        TodoListDTO(
            id: id,
            name: name,
            colorHex: colorHex,
            icon: icon,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
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
