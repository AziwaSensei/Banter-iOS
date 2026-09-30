//
//  Game.swift
//  Banter-iOS
//
//  Created by Ali Ziwa on 9/29/26.
//
import Foundation

// MARK: - What the app uses

/// One game, in the app's own terms.
struct Matchup {
    let name: String          // "Miami Heat at Toronto Raptors"
    let date: Date?
    let statusDetail: String  // "10/3 - 7:00 PM EDT" or "Final"
    let completed: Bool
    let homeTeam: String
    let awayTeam: String
    let homeScore: String?
    let awayScore: String?

    /// "Heat 98 - 101 Raptors" once played, otherwise the kickoff time.
    var summary: String {
        if completed, let homeScore, let awayScore {
            return "\(awayTeam) \(awayScore) - \(homeScore) \(homeTeam) (Final)"
        }
        return "\(name): \(statusDetail)"
    }
}

// MARK: - What ESPN sends

struct Game: Decodable {
    let name: String
    let date: String        // "2026-10-03T23:00Z"
    let status: Status
    let competitions: [Competition]

    struct Status: Decodable {
        let type: StatusType
        struct StatusType: Decodable {
            let shortDetail: String
            let completed: Bool
        }
    }

    struct Competition: Decodable {
        let competitors: [Competitor]
    }

    struct Competitor: Decodable {
        let homeAway: String    // "home" or "away"
        let score: String?
        let team: Team
        struct Team: Decodable {
            let displayName: String
        }
    }
}

extension Game {
    func matchup() -> Matchup {
        let competitors = competitions.first?.competitors ?? []
        let home = competitors.first { $0.homeAway == "home" }
        let away = competitors.first { $0.homeAway == "away" }
        return Matchup(
            name: name,
            date: Self.dateFormatter.date(from: date),
            statusDetail: status.type.shortDetail,
            completed: status.type.completed,
            homeTeam: home?.team.displayName ?? "",
            awayTeam: away?.team.displayName ?? "",
            homeScore: home?.score,
            awayScore: away?.score
        )
    }

    /// ESPN writes dates as "2026-10-03T23:00Z", which has no seconds, so the ISO 8601 parser rejects it.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
