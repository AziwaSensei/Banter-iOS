//
//  SportsScheduleTool.swift
//  Banter-iOS
//
//  Created by Ali Ziwa on 9/29/26.
//
import Foundation
import FoundationModels

/// This week's games for the league the user picked.
struct SportsScheduleTool: Tool {
    let name = "getSportsSchedule"
    let description = "Looks up this week's games, kickoff times, scores and results for the user's league."

    let league: League
    let store: LeagueStore

    /// No inputs: the league is already chosen. The framework still wants an arguments type.
    @Generable
    struct Arguments {}

    func call(arguments: Arguments) async throws -> String {
        let matchups: [Matchup]
        do {
            matchups = try await store.matchups(for: league)
        } catch {
            return "Could not get the schedule: \(error.localizedDescription)"
        }
        guard !matchups.isEmpty else {
            return "No games are scheduled in the \(league.displayName) this week."
        }
        return matchups.map(\.summary).joined(separator: "\n")
    }
}
