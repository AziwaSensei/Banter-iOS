//
//  League.swift
//  Banter-iOS
//
//  Created by Ali Ziwa on 9/29/26.
//
import FoundationModels

/// The leagues the app knows. The raw value is the path ESPN uses.
@Generable
enum League: String, CaseIterable, Identifiable {
    case nfl = "football/nfl"
    case nba = "basketball/nba"
    case mlb = "baseball/mlb"
    case nhl = "hockey/nhl"
    case premierLeague = "soccer/eng.1"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nfl: "NFL"
        case .nba: "NBA"
        case .mlb: "MLB"
        case .nhl: "NHL"
        case .premierLeague: "Premier League"
        }
    }

    var emoji: String {
        switch self {
        case .nfl: "🏈"
        case .nba: "🏀"
        case .mlb: "⚾️"
        case .nhl: "🏒"
        case .premierLeague: "⚽️"
        }
    }

    /// Prompts shown on the empty chat screen. Each one exercises a tool.
    var suggestions: [String] {
        switch self {
        case .nfl: ["Who plays this week?", "Show me the AFC standings", "How are the Chiefs doing?"]
        case .nba: ["Any games tonight?", "Show me the standings", "How are the Lakers doing?"]
        case .mlb: ["Who's playing today?", "Show me the standings", "How are the Yankees doing?"]
        case .nhl: ["Any games tonight?", "Show me the standings", "How are the Bruins doing?"]
        case .premierLeague: ["What are this week's fixtures?", "Show me the table", "How is Arsenal doing?"]
        }
    }
}
