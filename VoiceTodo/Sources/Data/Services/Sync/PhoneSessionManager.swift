//
//  PhoneSessionManager.swift
//  VoiceTodo
//
//  PLAN.md §6, phone side: dedupe incoming ops, apply them, acknowledge, and push changes back.
//

import Combine
import Foundation
import VoxoShared
import WatchConnectivity

@MainActor
final class PhoneSessionManager: NSObject, ObservableObject {
    @Published private(set) var lastSyncAt: Date?
    @Published private(set) var isWatchAppInstalled: Bool = false
    @Published private(set) var lastError: String?

    private let repository: TodoRepository & ProcessedOpLog
    private let session: WCSession?
    private let onRemoteChange: () -> Void

    init(repository: TodoRepository & ProcessedOpLog, onRemoteChange: @escaping () -> Void) {
        self.repository = repository
        self.onRemoteChange = onRemoteChange
        session = WCSession.isSupported() ? .default : nil
        super.init()
    }

    func start() {
        guard let session else { return }
        session.delegate = self
        session.activate()
    }

    /// Phone -> watch: the full current state of a todo that changed (PLAN.md §6).
    func push(_ todo: TodoDTO) {
        guard let session, session.activationState == .activated else { return }
        do {
            session.transferUserInfo(try SyncMessage.todo(todo).encoded())
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Shared settings use application context: only the latest value matters (PLAN.md §6).
    func pushSettings(globalIntervalMinutes: Int, languageCode: String? = nil) {
        guard let session, session.activationState == .activated else { return }
        do {
            try session.updateApplicationContext([
                "globalIntervalMinutes": globalIntervalMinutes,
                // The watch has no language switch of its own; it follows the phone's.
                "languageCode": languageCode ?? LanguageManager.shared.currentLanguageCode
            ])
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Incoming

    private func handle(_ message: SyncMessage) {
        guard case let .op(op) = message else { return }

        do {
            // PLAN.md §6.3: a repeated opId must change nothing, but still gets acknowledged —
            // the watch may simply have missed the first ACK.
            if try repository.markProcessed(opId: op.opId, now: Date()) {
                _ = try repository.apply(remote: op.decodeTodo())
                onRemoteChange()
            }
            acknowledge([op.opId])
            lastSyncAt = Date()
        } catch {
            // No ACK on failure, so the watch keeps the op and retries (PLAN.md §6.6).
            lastError = error.localizedDescription
        }
    }

    private func acknowledge(_ opIds: [UUID]) {
        guard let session, session.activationState == .activated else { return }
        do {
            session.transferUserInfo(try SyncMessage.ack(opIds).encoded())
        } catch {
            lastError = error.localizedDescription
        }
    }
}

// MARK: - WCSessionDelegate

extension PhoneSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith _: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isWatchAppInstalled = session.isWatchAppInstalled
            if let error { lastError = error.localizedDescription }
        }
    }

    nonisolated func session(_: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            do {
                guard let message = try SyncMessage.decode(from: userInfo) else { return }
                handle(message)
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_: WCSession) {}

    /// Required on iOS: the session drops when the user switches to another watch.
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            isWatchAppInstalled = session.isWatchAppInstalled
        }
    }
}
