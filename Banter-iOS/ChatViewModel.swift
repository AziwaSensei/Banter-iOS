//
//  ChatViewModel.swift
//  Banter-iOS
//

import Foundation
import Observation

@MainActor
@Observable
final class ChatViewModel {
    private(set) var selectedLeague: League?
    private(set) var messages: [ChatMessage] = []
    private(set) var isWaitingForReply = false

    let store: LeagueStore
    private let guardrail = Guardrail()
    private var agent: ChatAgent?

    private static let leagueKey = "selectedLeague"

    init(store: LeagueStore) {
        self.store = store
        if let saved = UserDefaults.standard.string(forKey: Self.leagueKey),
           let league = League(rawValue: saved) {
            select(league)
        }
    }

    // MARK: - League

    /// Picks a league: a fresh agent, an empty chat, and a download of that league's data.
    func select(_ league: League) {
        selectedLeague = league
        agent = ChatAgent(league: league, store: store)
        messages = []
        UserDefaults.standard.set(league.rawValue, forKey: Self.leagueKey)
        Task { try? await store.sync(league) }
    }

    /// Back to the league picker.
    func changeLeague() {
        selectedLeague = nil
        agent = nil
        messages = []
        UserDefaults.standard.removeObject(forKey: Self.leagueKey)
    }

    // MARK: - Chat

    func send(_ text: String) async {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isWaitingForReply, let agent, let league = selectedLeague else { return }

        messages.append(ChatMessage(text: text, role: .user))
        isWaitingForReply = true
        defer { isWaitingForReply = false }

        guard await guardrail.allows(text) else {
            messages.append(ChatMessage(
                text: "I only talk sports. Try asking about \(league.displayName) games, scores or standings.",
                role: .agent
            ))
            return
        }

        do {
            let reply = try await agent.respond(to: text)
            let attachment = await attachment(for: reply.toolsUsed, league: league)
            messages.append(ChatMessage(text: reply.text, role: .agent, attachment: attachment))
        } catch {
            messages.append(ChatMessage(text: error.localizedDescription, role: .agent, isError: true))
        }
    }

    /// If the model looked something up, show the user the same rows as a table.
    private func attachment(for toolsUsed: [String], league: League) async -> ChatMessage.Attachment? {
        if toolsUsed.contains("getSportsStandings"),
           let rows = try? await store.standings(for: league), !rows.isEmpty {
            return .standings(rows)
        }
        if toolsUsed.contains("getSportsSchedule"),
           let rows = try? await store.matchups(for: league), !rows.isEmpty {
            return .matchups(rows)
        }
        return nil
    }
}
