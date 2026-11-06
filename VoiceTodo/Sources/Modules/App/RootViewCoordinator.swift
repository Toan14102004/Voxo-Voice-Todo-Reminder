//
//  RootViewCoordinator.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 18/11/24.
//

import Foundation

extension RootView {
    struct Coordinator: BaseCoordinator {
        enum Navigation: BaseNavigation {
            case language
            case content
        }

        enum FullScreen: BaseFullScreen {
            case subscription(subscriptionEntryPoint: SubscriptionView.SubscriptionEntryPoint)
        }
    }
}
