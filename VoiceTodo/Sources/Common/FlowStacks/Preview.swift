//
//  Preview.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 20/5/25.
//

import Foundation
import SwiftUI

extension View {
    public func preview() -> some View {
        modifier(PreviewModifier())
    }
}

struct PreviewModifier: ViewModifier {
    
    @State var path = FlowPath()
    
    func body(content: Content) -> some View {
        FlowStack($path, withNavigation: true) {
            content
                .modifier(NavigatorModifier())
                .onFirstAppear {
                    let dependencies = Dependencies {
                        Dependency { LocalStorageService() }
                        Dependency { NetworkService() }
                        Dependency { FileStorageManager() }
                        Dependency { NetworkService() }
                        Dependency { DatabaseService.createDefault() }
                        Dependency { KeychainStorage() }
                        Dependency { AdsPreloadService() }
                        Dependency { SubscriptionManager() }
                        Dependency { AdsManager() }
                        Dependency { FirebaseAnalyticsService() }
                    }
                    dependencies.build()
                }
                .environmentObject(SubscriptionManager())
        }
    }
}
