//
//  AppGradient.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 29/9/25.
//

import Foundation
import SwiftUI

enum AppGradient {
    static var mainGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#00C6FF"),
                Color(hex: "#0072FF")
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
