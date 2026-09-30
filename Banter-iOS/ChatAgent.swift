//
//  ChatAgent.swift
//  Banter-iOS
//
//  Created by Ali Ziwa on 9/28/26.
//

import FoundationModels

/// One agent, one on-device model session, one league.
///
/// The session keeps its own transcript, so follow-up messages see the earlier ones.
/// `instructions` plays the role of a system prompt. The tools are what the model may
/// call when it decides it needs outside information.
@MainActor
final class ChatAgent {
    let league: League
    private let session: LanguageModelSession

    /// What the model wrote, plus which tools it called on the way.
    struct Reply {
        let text: String
        let toolsUsed: [String]
    }

    init(league: League, store: LeagueStore) {
        self.league = league
        session = LanguageModelSession(
            tools: [
                SportsScheduleTool(league: league, store: store),
                SportsStandingsTool(league: league, store: store),
                DateTool(),
            ],
            instructions: Self.instructions(for: league)
        )
    }

    /// Sends `message` to the model and returns its reply.
    func respond(to message: String) async throws -> Reply {
        let alreadySeen = session.transcript.count
        let response = try await session.respond(to: message)

        // Anything added to the transcript during this turn is ours. Pull out the tool calls.
        let toolsUsed = session.transcript.dropFirst(alreadySeen).flatMap { entry -> [String] in
            if case .toolCalls(let calls) = entry {
                return calls.map(\.toolName)
            }
            return []
        }
        return Reply(text: response.content, toolsUsed: toolsUsed)
    }

    private static func instructions(for league: League) -> String {
        """
        You are a \(league.displayName) specialist in a group chat. You only talk about sports.
        If asked about anything else, say you only talk sports and suggest a \(league.displayName) question.
        You do not know today's date. Whenever a question involves a date or time, such as \
        "tonight", "this week" or "yesterday", call the getCurrentDate tool first.
        When asked about games, fixtures, scores or results, call the getSportsSchedule tool. \
        When asked about standings, rankings, the table, or how a team is doing this season, \
        call the getSportsStandings tool. Answer only from what the tools return. \
        If a tool says it could not get data, say so.
        Keep replies to two or three sentences. The app shows the full table under your reply, \
        so summarise rather than list every team.
        """
    }
}
