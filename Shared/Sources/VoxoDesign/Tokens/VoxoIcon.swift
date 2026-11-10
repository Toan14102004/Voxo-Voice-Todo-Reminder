//
//  VoxoIcon.swift
//  VoxoDesign
//
//  The design specifies Material Symbols Rounded; we ship SF Symbols instead, because the
//  Material variable font is 15 MB against a 3 MB Watch app. This table is the whole deviation,
//  Figma name beside SF name, so it can be checked against the board.
//

import Foundation

public enum VoxoIcon {
    // Figma name            -> SF Symbol
    public static let check = "checkmark"                       // check
    public static let unchecked = "circle"                      // (circle outline in the design)
    public static let checked = "checkmark.circle.fill"
    public static let add = "plus"                              // add
    public static let date = "calendar"                         // calendar_today, event
    public static let time = "clock"                            // schedule
    public static let alarm = "alarm"                           // alarm
    public static let repeatRule = "repeat"                     // repeat
    public static let list = "folder"                           // folder
    public static let priority = "flag"                         // flag
    public static let streak = "flame.fill"                     // local_fire_department
    public static let rate = "checkmark.circle"                 // check_circle
    public static let home = "house"                            // home
    public static let note = "text.alignleft"                   // (note field in Quick add)

    /// Tab bar. `today` and `calendar_month` both map to a calendar in SF, so Today uses a
    /// checklist to stay distinct from Calendar.
    public enum Tab {
        public static let today = "checklist"                   // today
        public static let calendar = "calendar"                 // calendar_month
        public static let lists = "list.bullet"                 // format_list_bulleted
        public static let stats = "chart.bar"                   // bar_chart
    }
}
