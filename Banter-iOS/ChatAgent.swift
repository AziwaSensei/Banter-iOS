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
    private let store: LeagueStore
    private var session: LanguageModelSession

    /// What the model wrote, plus which tools it called on the way.
    struct Reply {
        let text: String
        let toolsUsed: [String]
    }

    init(league: League, store: LeagueStore) {
        self.league = league
        self.store = store
        session = Self.makeSession(league: league, store: store)
    }

    private static func makeSession(
        league: League,
        store: LeagueStore,
        transcript: Transcript? = nil
    ) -> LanguageModelSession {
        let tools: [any Tool] = [
            SportsScheduleTool(league: league, store: store),
            SportsStandingsTool(league: league, store: store),
            DateTool(),
        ]
        if let transcript {
            return LanguageModelSession(tools: tools, transcript: transcript)
        }
        return LanguageModelSession(tools: tools, instructions: instructions(for: league))
    }

    /// Sends `message` to the model and returns its reply.
    ///
    /// The on-device model has a fixed context window (4,096 tokens on iOS 26, 8,192 on the
    /// iOS 27 simulator) shared by the instructions, every prompt, every reply and every tool
    /// result. A long chat of standings tables will eventually exceed it, and once it does the
    /// session never recovers on its own. So the overflow is caught, the session is rebuilt from
    /// a condensed transcript (just the instructions) and the message is sent once more. The
    /// user loses the earlier turns, not the answer.
    func respond(to message: String) async throws -> Reply {
        do {
            return try await send(message)
        } catch where Self.isContextOverflow(error) {
            session = Self.makeSession(league: league, store: store, transcript: condensedTranscript())
            return try await send(message)
        }
    }

    /// iOS 27 renamed the error: `GenerationError.exceededContextWindowSize` is deprecated and
    /// the session now throws `LanguageModelError.contextSizeExceeded`, which also carries the
    /// window size and the token count that tripped it. A catch written against the old name
    /// lets the new error straight through, and every turn after it fails the same way. Both
    /// are checked here, and either may arrive wrapped in a `ToolCallError` when it is a
    /// tool's output that pushes the transcript over.
    private static func isContextOverflow(_ error: any Error) -> Bool {
        if #available(iOS 27, *), case LanguageModelError.contextSizeExceeded = error { return true }
        if case LanguageModelSession.GenerationError.exceededContextWindowSize = error { return true }
        if let toolError = error as? LanguageModelSession.ToolCallError {
            return isContextOverflow(toolError.underlyingError)
        }
        return false
    }

    /// Keeps only the instructions. Everything the model said before is dropped; the tools
    /// can fetch the facts again, and that is cheaper than carrying old tables around.
    private func condensedTranscript() -> Transcript {
        let kept = session.transcript.prefix { entry in
            if case .instructions = entry { return true }
            return false
        }
        return Transcript(entries: Array(kept))
    }

    private func send(_ message: String) async throws -> Reply {
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
