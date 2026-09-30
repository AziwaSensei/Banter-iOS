//
//  MessageInputView.swift
//  Banter-iOS
//
//  Created by Ali Ziwa on 9/28/26.
//

import SwiftUI

struct MessageInputView: View {
    @Binding var currentTextInput: String
    var isSending = false
    var tint: Color = .accentColor
    var onSendButtonTap: () async -> Void

    private var canSend: Bool {
        !currentTextInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    var body: some View {
        HStack(spacing: 10) {
            TextField("Ask about a game…", text: $currentTextInput)
                .submitLabel(.send)
                .onSubmit { send() }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground), in: Capsule())

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(tint)
            }
            .disabled(!canSend)
            .opacity(canSend ? 1 : 0.4)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func send() {
        guard canSend else { return }
        Task { await onSendButtonTap() }
    }
}
