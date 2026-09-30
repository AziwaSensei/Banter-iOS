//
//  SportsStandingsTool.swift
//  Banter-iOS
//

import Foundation
import FoundationModels

/// The standings table for the league the user picked.
struct SportsStandingsTool: Tool {
    let name = "getSportsStandings"
    let description = "Looks up the current standings for the user's league: each team's rank, record and points."

    let league: League
    let store: LeagueStore

    @Generable
    struct Arguments {
        @Guide(description: "A team name to narrow the table to, when the user asks about one team. Leave empty for the whole table.")
        var team: String?
    }

    func call(arguments: Arguments) async throws -> String {
        let standings: [TeamStanding]
        do {
            standings = try await store.standings(for: league)
        } catch {
            return "Could not get standings: \(error.localizedDescription)"
        }

        let wanted = arguments.team?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
        let rows = wanted.isEmpty
            ? standings
            : standings.filter { $0.team.lowercased().contains(wanted) }

        guard !rows.isEmpty else {
            return wanted.isEmpty
                ? "No standings are available for the \(league.displayName) right now."
                : "No team matching '\(arguments.team ?? "")' in the \(league.displayName) standings."
        }

        // One block per group, one compact line per team, so a small model can read it.
        var lines: [String] = []
        var currentGroup = ""
        for row in rows {
            if row.group != currentGroup {
                currentGroup = row.group
                lines.append("\n\(currentGroup):")
            }
            var line = "\(row.rank.map { "\($0). " } ?? "")\(row.team) \(row.record)"
            if let points = row.points { line += ", \(points) pts" }
            if let played = row.gamesPlayed { line += ", \(played) played" }
            lines.append(line)
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
