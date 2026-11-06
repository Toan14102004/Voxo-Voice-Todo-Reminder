//
//  SyncOpDTO.swift
//  VoxoShared
//

import Foundation

public enum SyncOpType: String, Codable, Sendable {
    case create
    case update
    case complete
    case delete
}

/// One queued change from the Watch, as defined in PLAN.md §4.
///
/// `payload` carries the JSON-encoded `TodoDTO` the operation refers to, so the phone can apply it
/// without asking the watch for anything else.
public struct SyncOpDTO: Codable, Equatable, Identifiable, Sendable {
    public var opId: UUID
    public var todoId: UUID
    public var type: SyncOpType
    public var payload: Data
    public var createdAt: Date

    public var id: UUID { opId }

    public init(opId: UUID = UUID(), todoId: UUID, type: SyncOpType, payload: Data, createdAt: Date) {
        self.opId = opId
        self.todoId = todoId
        self.type = type
        self.payload = payload
        self.createdAt = createdAt
    }

    public init(opId: UUID = UUID(), type: SyncOpType, todo: TodoDTO, createdAt: Date) throws {
        self.init(
            opId: opId,
            todoId: todo.id,
            type: type,
            payload: try VoxoCoder.encoder.encode(todo),
            createdAt: createdAt
        )
    }

    public func decodeTodo() throws -> TodoDTO {
        try VoxoCoder.decoder.decode(TodoDTO.self, from: payload)
    }
}

/// One coder pair for everything that crosses the wire, so both sides agree on date encoding.
public enum VoxoCoder {
    public static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
