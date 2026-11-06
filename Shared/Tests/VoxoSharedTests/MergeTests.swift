//
//  MergeTests.swift
//  VoxoSharedTests
//
//  Covers the conflict rules in PLAN.md §6 and the cases §8 Phase 3 asks for.
//

import XCTest
@testable import VoxoShared

final class MergeTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    private func todo(
        id: UUID,
        title: String = "Mua sữa",
        updatedAt: Date,
        deletedAt: Date? = nil,
        isDone: Bool = false,
        origin: DeviceRole = .watch
    ) -> TodoDTO {
        TodoDTO(
            id: id,
            title: title,
            isDone: isDone,
            createdAt: t0,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDevice: origin
        )
    }

    func testInsertsWhenNoLocalCopy() {
        let incoming = todo(id: UUID(), updatedAt: t0)
        let outcome = MergeService(device: .phone).merge(local: nil, incoming: incoming)
        XCTAssertEqual(outcome, .insert(incoming))
    }

    func testNewerIncomingWins() {
        let id = UUID()
        let local = todo(id: id, title: "cũ", updatedAt: t0)
        let incoming = todo(id: id, title: "mới", updatedAt: t0.addingTimeInterval(10))

        XCTAssertEqual(MergeService(device: .phone).merge(local: local, incoming: incoming), .update(incoming))
    }

    func testOlderIncomingIsDropped() {
        let id = UUID()
        let local = todo(id: id, title: "mới", updatedAt: t0.addingTimeInterval(10))
        let incoming = todo(id: id, title: "cũ", updatedAt: t0)

        XCTAssertEqual(MergeService(device: .phone).merge(local: local, incoming: incoming), .keepLocal)
    }

    /// PLAN.md §6: "Nếu bằng nhau, ưu tiên bản từ iPhone."
    func testEqualTimestampsFavourThePhoneOnBothDevices() {
        let id = UUID()
        let local = todo(id: id, title: "bản máy này", updatedAt: t0)
        let incoming = todo(id: id, title: "bản máy kia", updatedAt: t0)

        // On the phone the local copy is the phone's, so it holds.
        XCTAssertEqual(MergeService(device: .phone).merge(local: local, incoming: incoming), .keepLocal)
        // On the watch the incoming copy is the phone's, so it wins.
        XCTAssertEqual(MergeService(device: .watch).merge(local: local, incoming: incoming), .update(incoming))
    }

    func testTombstoneBeatsANewerEdit() {
        let id = UUID()
        let local = todo(id: id, title: "sửa sau khi xoá", updatedAt: t0.addingTimeInterval(1000))
        let incoming = todo(id: id, updatedAt: t0, deletedAt: t0)

        // v1 has no restore, so the delete wins even though the local edit is newer.
        XCTAssertEqual(MergeService(device: .phone).merge(local: local, incoming: incoming), .update(incoming))
    }

    func testEditNeverResurrectsALocalTombstone() {
        let id = UUID()
        let local = todo(id: id, updatedAt: t0, deletedAt: t0)
        let incoming = todo(id: id, title: "sửa sau khi xoá", updatedAt: t0.addingTimeInterval(1000))

        XCTAssertEqual(MergeService(device: .phone).merge(local: local, incoming: incoming), .keepLocal)
    }

    func testTwoTombstonesKeepTheEarlierOne() {
        let id = UUID()
        let early = t0
        let late = t0.addingTimeInterval(5000)
        let local = todo(id: id, updatedAt: late, deletedAt: late)
        let incoming = todo(id: id, updatedAt: early, deletedAt: early)

        // Keeping the earlier deletedAt stops the 30-day purge clock from restarting.
        XCTAssertEqual(MergeService(device: .phone).merge(local: local, incoming: incoming), .update(incoming))
    }

    func testSimultaneousEditsOnBothDevicesConvergeToTheSameWinner() {
        let id = UUID()
        let fromWatch = todo(id: id, title: "bản watch", updatedAt: t0, origin: .watch)
        let fromPhone = todo(id: id, title: "bản phone", updatedAt: t0, origin: .phone)

        // Phone merging the watch's version keeps its own.
        let onPhone = MergeService(device: .phone).merge(local: fromPhone, incoming: fromWatch)
        // Watch merging the phone's version takes it.
        let onWatch = MergeService(device: .watch).merge(local: fromWatch, incoming: fromPhone)

        XCTAssertEqual(onPhone, .keepLocal)
        XCTAssertEqual(onWatch, .update(fromPhone))
        // Both devices end up showing the phone's title — no split brain.
    }

    func testPurgeWindowIsThirtyDays() {
        let merger = MergeService(device: .phone)
        let deletedAt = t0
        let justUnder = deletedAt.addingTimeInterval(MergeService.tombstoneRetention - 1)
        let justOver = deletedAt.addingTimeInterval(MergeService.tombstoneRetention)
        let tombstone = todo(id: UUID(), updatedAt: deletedAt, deletedAt: deletedAt)

        XCTAssertFalse(merger.isPurgeable(tombstone, olderThan: MergeService.tombstoneRetention, now: justUnder))
        XCTAssertTrue(merger.isPurgeable(tombstone, olderThan: MergeService.tombstoneRetention, now: justOver))
        XCTAssertFalse(merger.isPurgeable(todo(id: UUID(), updatedAt: t0), olderThan: MergeService.tombstoneRetention, now: justOver))
    }
}
