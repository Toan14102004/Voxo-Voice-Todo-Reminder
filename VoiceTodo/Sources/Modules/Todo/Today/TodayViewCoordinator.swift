//
//  TodayViewCoordinator.swift
//  VoiceTodo
//

import Foundation

extension TodayView {
    struct Coordinator: BaseCoordinator {
        enum Navigation: BaseNavigation {
            /// Routes carry the id so the destination reads the current record, not a snapshot.
            case detail(UUID)
            case settings
        }

        enum FullScreen: BaseFullScreen {
            case quickAdd
        }
    }
}
