//
//  Guardrail.swift
//  Banter-iOS
//
//  A yes/no question asked of the model before the agent ever sees the message.
//  Structured generation means the answer comes back as a Bool, not as prose to parse.
//

import FoundationModels

struct Guardrail {

    @Generable
    struct Verdict {
        @Guide(description: "True when the message is about sports, or is a greeting, thanks, or small talk about this chat. False for anything else, such as programming, homework, recipes or general trivia.")
        let isOnTopic: Bool
    }

    /// Returns true when the agent should answer `message`.
    ///
    /// Fails open: if the classifier itself errors, the message goes through and the agent's
    /// own instructions are the fallback.
    func allows(_ message: String) async -> Bool {
        let session = LanguageModelSession(instructions: """
            You are a strict topic classifier for a sports chat app. \
            Decide whether the user's message belongs in a conversation about sports.
            """)
        do {
            return try await session.respond(to: message, generating: Verdict.self).content.isOnTopic
        } catch {
            return true
        }
    }
}
