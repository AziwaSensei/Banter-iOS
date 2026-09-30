//
//  LeagueStore.swift
//  Banter-iOS
//
//  The one place that decides "database or network?".
//
//  Reads come from SwiftData first. If the rows are missing or older than `freshFor`, the store
//  downloads a fresh copy and replaces them. If the download fails but old rows exist, the old
//  rows are returned, so being offline degrades to "slightly stale" rather than "broken".
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class LeagueStore {
    /// How long a download is trusted before the next read refreshes it.
    static let freshFor: TimeInterval = 15 * 60

    private(set) var isSyncing = false
    private(set) var lastSyncError: String?

    private let context: ModelContext
    private let api = SportsApiService()

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Reads

    func standings(for league: League) async throws -> [TeamStanding] {
        let cached = try cachedStandings(for: league)
        if let first = cached.first, isFresh(first.fetchedAt) {
            return cached.map(\.standing)
        }
        do {
            try await sync(league)
        } catch where !cached.isEmpty {
            return cached.map(\.standing)
        }
        return try cachedStandings(for: league).map(\.standing)
    }

    func matchups(for league: League) async throws -> [Matchup] {
        let cached = try cachedGames(for: league)
        if let first = cached.first, isFresh(first.fetchedAt) {
            return cached.map(\.matchup)
        }
        do {
            try await sync(league)
        } catch where !cached.isEmpty {
            return cached.map(\.matchup)
        }
        return try cachedGames(for: league).map(\.matchup)
    }

    // MARK: - Download

    /// Downloads standings and this week's games for `league` and replaces what was stored.
    func sync(_ league: League) async throws {
        isSyncing = true
        lastSyncError = nil
        defer { isSyncing = false }

        do {
            async let standings = api.getStandings(for: league)
            async let matchups = api.getMatchups(for: league)
            let (rows, games) = try await (standings, matchups)

            let now = Date()
            try deleteRows(for: league)
            for (index, row) in rows.enumerated() {
                context.insert(CachedStanding(row, league: league, order: index, fetchedAt: now))
            }
            for (index, game) in games.enumerated() {
                context.insert(CachedGame(game, league: league, order: index, fetchedAt: now))
            }
            try context.save()
        } catch {
            lastSyncError = error.localizedDescription
            throw error
        }
    }

    // MARK: - SwiftData plumbing

    private func cachedStandings(for league: League) throws -> [CachedStanding] {
        let key = league.rawValue
        let descriptor = FetchDescriptor<CachedStanding>(
            predicate: #Predicate { $0.league == key },
            sortBy: [SortDescriptor(\.order)]
        )
        return try context.fetch(descriptor)
    }

    private func cachedGames(for league: League) throws -> [CachedGame] {
        let key = league.rawValue
        let descriptor = FetchDescriptor<CachedGame>(
            predicate: #Predicate { $0.league == key },
            sortBy: [SortDescriptor(\.order)]
        )
        return try context.fetch(descriptor)
    }

    private func deleteRows(for league: League) throws {
        let key = league.rawValue
        try context.delete(model: CachedStanding.self, where: #Predicate { $0.league == key })
        try context.delete(model: CachedGame.self, where: #Predicate { $0.league == key })
    }

    private func isFresh(_ date: Date) -> Bool {
        Date().timeIntervalSince(date) < Self.freshFor
    }
}
