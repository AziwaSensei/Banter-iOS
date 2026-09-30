//
//  ChatMessage.swift
//  Banter-iOS
//

import Foundation

/// One line in the conversation, who said it, and any table that came with it.
struct ChatMessage: Identifiable {
    enum Role {
        case user, agent
    }

    /// Structured data the bubble can draw, on top of the text the model wrote.
    enum Attachment {
        case standings([TeamStanding])
        case matchups([Matchup])
    }

    let id = UUID()
    let text: String
    let role: Role
    var isError = false
    var attachment: Attachment? = nil
}
