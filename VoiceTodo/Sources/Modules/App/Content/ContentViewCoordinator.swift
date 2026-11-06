//
//  ContentViewCoordinator.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 26/9/25.
//

import Foundation
import SwiftUI

extension ContentView {
  struct Coordinator: BaseCoordinator {
    enum Alert: BaseAlert {
      case error(title: String, message: String)
      case success(title: String, message: String)
    }

    enum Navigation: BaseNavigation {
      case settingView
      case languageView
    }

    var alert: Alert?
  }
}
