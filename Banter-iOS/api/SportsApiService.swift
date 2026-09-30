//
//  SportsApiService.swift
//  Banter-iOS
//
//  Created by Ali Ziwa on 9/29/26.
//
import Foundation

/// Every ESPN URL the app knows, built in one place.
///
/// Both live on the same host. The scoreboard sits under `apis/site/v2`, standings under `apis/v2`.
/// The `apis/site/v2/.../standings` path exists but only returns a link to espn.com.
enum SportsEndpoint {
    case scoreboard(League)
    case standings(League)

    var url: URL {
        switch self {
        case .scoreboard(let league):
            URL(string: "https://site.api.espn.com/apis/site/v2/sports/\(league.rawValue)/scoreboard")!
        case .standings(let league):
            URL(string: "https://site.api.espn.com/apis/v2/sports/\(league.rawValue)/standings")!
        }
    }
}

struct SportsApiService: ApiService {

    func getMatchups(for league: League) async throws -> [Matchup] {
        let scoreboard: Scoreboard = try await get(SportsEndpoint.scoreboard(league).url)
        return scoreboard.events.map { $0.matchup() }
    }

    func getStandings(for league: League) async throws -> [TeamStanding] {
        let response: StandingsResponse = try await get(SportsEndpoint.standings(league).url)
        return response.teamStandings()
    }
}
