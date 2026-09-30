//
//  TypingIndicatorView.swift
//  Banter-iOS
//

import SwiftUI

/// Shown while the agent is thinking. Three dots that pulse in turn.
struct TypingIndicatorView: View {
    var body: some View {
        HStack {
            Image(systemName: "ellipsis")
                .font(.title2)
                .symbolEffect(.variableColor.iterative)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer()
        }
        .padding(.leading, 36)
    }
}
