//
//  CachedModels.swift
//  Banter-iOS
//
//  The SwiftData rows. Each one is a plain copy of an app model plus the league it belongs to,
//  its position in the list, and when it was downloaded.
//

import Foundation
import SwiftData

@Model
final class CachedStanding {
    var league: String
    var order: Int
    var fetchedAt: Date

    var team: String
    var group: String
    var rank: Int?
    var wins: Int
    var losses: Int
    var ties: Int?
    var points: Int?
    var gamesPlayed: Int?

    init(_ standing: TeamStanding, league: League, order: Int, fetchedAt: Date) {
        self.league = league.rawValue
        self.order = order
        self.fetchedAt = fetchedAt
        team = standing.team
        group = standing.group
        rank = standing.rank
        wins = standing.wins
        losses = standing.losses
        ties = standing.ties
        points = standing.points
        gamesPlayed = standing.gamesPlayed
    }

    var standing: TeamStanding {
        TeamStanding(team: team, group: group, rank: rank, wins: wins, losses: losses,
                     ties: ties, points: points, gamesPlayed: gamesPlayed)
    }
}

@Model
final class CachedGame {
    var league: String
    var order: Int
    var fetchedAt: Date

    var name: String
    var date: Date?
    var statusDetail: String
    var completed: Bool
    var homeTeam: String
    var awayTeam: String
    var homeScore: String?
    var awayScore: String?

    init(_ matchup: Matchup, league: League, order: Int, fetchedAt: Date) {
        self.league = league.rawValue
        self.order = order
        self.fetchedAt = fetchedAt
        name = matchup.name
        date = matchup.date
        statusDetail = matchup.statusDetail
        completed = matchup.completed
        homeTeam = matchup.homeTeam
        awayTeam = matchup.awayTeam
        homeScore = matchup.homeScore
        awayScore = matchup.awayScore
    }

    var matchup: Matchup {
        Matchup(name: name, date: date, statusDetail: statusDetail, completed: completed,
                homeTeam: homeTeam, awayTeam: awayTeam, homeScore: homeScore, awayScore: awayScore)
    }
}
