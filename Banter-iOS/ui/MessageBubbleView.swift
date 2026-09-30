//
//  MessageBubbleView.swift
//  Banter-iOS
//

import SwiftUI

/// A chat bubble. The user sits on the right in the league colour, the agent on the left.
/// If the reply came with a table, it is drawn under the text.
struct MessageBubbleView: View {
    let message: ChatMessage
    var tint: Color = .accentColor

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser {
                Spacer(minLength: 48)
            } else {
                avatar
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(message.text)
                    .textSelection(.enabled)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundStyle(textColor)
                    .background(bubbleColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                switch message.attachment {
                case .standings(let rows):
                    StandingsTableView(rows: rows, tint: tint)
                case .matchups(let rows):
                    MatchupsTableView(rows: rows, tint: tint)
                case nil:
                    EmptyView()
                }
            }

            if !isUser {
                Spacer(minLength: 24)
            }
        }
    }

    private var avatar: some View {
        Image(systemName: "sportscourt.fill")
            .font(.caption)
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(tint, in: Circle())
    }

    private var bubbleColor: Color {
        if message.isError { return .red.opacity(0.12) }
        return isUser ? tint : Color(.secondarySystemBackground)
    }

    private var textColor: Color {
        if message.isError { return .red }
        return isUser ? .white : .primary
    }
}
