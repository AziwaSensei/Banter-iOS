//
//  Standing.swift
//  Banter-iOS
//
//  Created by Ali Ziwa on 9/30/26.
//

// MARK: - What the app uses

/// One row of a standings table, in the app's own terms.
///
/// Leagues disagree on what a table holds: the NFL has no points column, the Premier League
/// has no playoff seed. Anything not shared by every league is optional.
struct TeamStanding {
    let team: String
    let group: String        // "Eastern Conference", "2026-27 English Premier League"
    let rank: Int?
    let wins: Int
    let losses: Int
    let ties: Int?
    let points: Int?
    let gamesPlayed: Int?

    /// "W3 L0" or "W2 D3 L0". Spelled out because "2-0-3" means different things in different sports.
    var record: String {
        var parts = ["W\(wins)"]
        if let ties, ties > 0 { parts.append("D\(ties)") }
        parts.append("L\(losses)")
        return parts.joined(separator: " ")
    }
}

// MARK: - What ESPN sends

/// ESPN's standings document. A league holds groups (conferences, or a single season for
/// soccer); each group holds a table; each table row is a team plus a list of named stats.
struct StandingsResponse: Decodable {
    let name: String
    let children: [Group]?
    let standings: Table?

    struct Group: Decodable {
        let name: String
        let children: [Group]?
        let standings: Table?
    }

    struct Table: Decodable {
        let entries: [Entry]
    }

    struct Entry: Decodable {
        let team: Team
        let stats: [Stat]
    }

    struct Team: Decodable {
        let displayName: String
    }

    /// Every value arrives as a string, even the numbers.
    struct Stat: Decodable {
        let name: String
        let displayValue: String?
    }
}

extension StandingsResponse {
    /// Flattens the nested document into rows, ordered by rank within each group.
    func teamStandings() -> [TeamStanding] {
        var rows: [TeamStanding] = []
        collect(groupName: name, table: standings, children: children, into: &rows)
        return rows
    }

    private func collect(groupName: String, table: Table?, children: [Group]?, into rows: inout [TeamStanding]) {
        if let table {
            let group = table.entries.map { $0.teamStanding(in: groupName) }
            rows += group.sorted { ($0.rank ?? .max) < ($1.rank ?? .max) }
        }
        for child in children ?? [] {
            collect(groupName: child.name, table: child.standings, children: child.children, into: &rows)
        }
    }
}

private extension StandingsResponse.Entry {
    func teamStanding(in group: String) -> TeamStanding {
        let value = Dictionary(stats.map { ($0.name, $0.displayValue ?? "") }, uniquingKeysWith: { first, _ in first })
        func int(_ key: String) -> Int? { Int(value[key] ?? "") }

        return TeamStanding(
            team: team.displayName,
            group: group,
            rank: int("rank") ?? int("playoffSeed"),
            wins: int("wins") ?? 0,
            losses: int("losses") ?? 0,
            ties: int("ties"),
            points: int("points"),
            gamesPlayed: int("gamesPlayed")
        )
    }
}
