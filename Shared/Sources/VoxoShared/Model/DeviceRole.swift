//
//  DeviceRole.swift
//  VoxoShared
//

import Foundation

/// Which device a record or a change came from.
///
/// PLAN.md §4 stores this on every todo as `originDevice`, and §6 uses it to break merge ties.
public enum DeviceRole: String, Codable, Sendable, CaseIterable {
    case phone
    case watch
}
