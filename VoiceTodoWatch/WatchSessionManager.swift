//
//  WatchSessionManager.swift
//  VoiceTodoWatch
//
//  PLAN.md §6, Watch side: queue locally, send, wait for ACK before dropping.
//

import Combine
import Foundation
import VoxoShared
import WatchConnectivity

@MainActor
final class WatchSessionManager: NSObject, ObservableObject {
    @Published private(set) var pendingOpCount: Int = 0
    @Published private(set) var isReachable: Bool = false
    @Published private(set) var lastError: String?

    /// Shared interval pushed from the phone with `updateApplicationContext`.
    @Published private(set) var globalIntervalMinutes: Int = SyncSettings.defaultIntervalMinutes

    /// The language picked in the phone app. Tidy switches language in-app, so following the
    /// watch's own system setting would show the two devices in different languages.
    @Published private(set) var languageCode: String = WatchSessionManager.storedLanguageCode

    var locale: Locale { Locale(identifier: languageCode) }

    private static let languageKey = "tidy.watch.languageCode"

    private static var storedLanguageCode: String {
        UserDefaults.standard.string(forKey: languageKey)
            ?? Locale.current.language.languageCode?.identifier
            ?? "en"
    }

    private let repository: TodoRepository & SyncOutbox
    private let session: WCSession?
    private let onRemoteChange: () -> Void

    init(repository: TodoRepository & SyncOutbox, onRemoteChange: @escaping () -> Void) {
        self.repository = repository
        self.onRemoteChange = onRemoteChange
        session = WCSession.isSupported() ? .default : nil
        super.init()
    }

    func start() {
        guard let session else {
            lastError = "Thiết bị không hỗ trợ WatchConnectivity"
            return
        }
        session.delegate = self
        session.activate()
        refreshPending()
    }

    /// Sends every queued op. Safe to call often — ops stay until the phone acknowledges them,
    /// so a resend is just a duplicate the phone will dedupe on `opId` (PLAN.md §6.3).
    func flushOutbox() {
        guard let session, session.activationState == .activated else { return }

        do {
            let ops = try repository.pendingOps()
            for op in ops {
                let payload = try SyncMessage.op(op).encoded()
                session.transferUserInfo(payload)
            }
            pendingOpCount = ops.count
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshPending() {
        pendingOpCount = (try? repository.pendingOpCount()) ?? 0
    }

    // MARK: - Incoming

    private func handle(_ message: SyncMessage) {
        switch message {
        case let .ack(opIds):
            do {
                _ = try repository.acknowledge(opIds: opIds)
                refreshPending()
            } catch {
                lastError = error.localizedDescription
            }

        case let .todo(dto):
            do {
                _ = try repository.apply(remote: dto)
                onRemoteChange()
            } catch {
                lastError = error.localizedDescription
            }

        case .op:
            // The phone never sends ops; ignore rather than treat as an error.
            break
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isReachable = session.isReachable
            if let error { lastError = error.localizedDescription }
            if state == .activated { flushOutbox() }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            if session.isReachable { flushOutbox() }
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

    nonisolated func session(_: WCSession, didReceiveApplicationContext context: [String: Any]) {
        Task { @MainActor in
            if let code = context["languageCode"] as? String, code != languageCode {
                languageCode = code
                // Persisted: the context is only delivered when the phone is in range, and the
                // watch has to come up in the right language on its own.
                UserDefaults.standard.set(code, forKey: Self.languageKey)
            }

            guard let minutes = context["globalIntervalMinutes"] as? Int,
                  SyncSettings.isValid(minutes) else { return }
            globalIntervalMinutes = minutes
        }
    }
}
