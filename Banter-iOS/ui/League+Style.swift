//
//  League+Style.swift
//  Banter-iOS
//
//  Each league gets its own colour so the whole screen changes mood when you switch.
//

import SwiftUI

extension League {
    var color: Color {
        switch self {
        case .nfl: Color(red: 0.05, green: 0.32, blue: 0.62)
        case .nba: Color(red: 0.79, green: 0.25, blue: 0.20)
        case .mlb: Color(red: 0.10, green: 0.42, blue: 0.30)
        case .nhl: Color(red: 0.15, green: 0.20, blue: 0.40)
        case .premierLeague: Color(red: 0.24, green: 0.05, blue: 0.40)
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
