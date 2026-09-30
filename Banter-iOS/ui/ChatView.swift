//
//  ChatView.swift
//  Banter-iOS
//

import SwiftUI

struct ChatView: View {
    let league: League

    @Environment(ChatViewModel.self) private var chatViewModel
    @State private var currentTextInput = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if chatViewModel.store.isSyncing {
                    syncBanner
                }
                if chatViewModel.messages.isEmpty {
                    emptyState
                } else {
                    conversation
                }
                MessageInputView(
                    currentTextInput: $currentTextInput,
                    isSending: chatViewModel.isWaitingForReply,
                    tint: league.color
                ) {
                    let text = currentTextInput
                    currentTextInput = ""
                    await chatViewModel.send(text)
                }
            }
            .background(background)
            .navigationTitle("\(league.emoji) \(league.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Leagues", systemImage: "chevron.left") {
                        chatViewModel.changeLeague()
                    }
                }
            }
            .tint(league.color)
        }
    }

    // MARK: - Pieces

    private var background: some View {
        LinearGradient(
            colors: [league.color.opacity(0.12), Color(.systemGroupedBackground)],
            startPoint: .top,
            endPoint: .center
        )
        .ignoresSafeArea()
    }

    private var syncBanner: some View {
        HStack(spacing: 8) {
            ProgressView()
            Text("Loading \(league.displayName) stats…")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(chatViewModel.messages) { message in
                        MessageBubbleView(message: message, tint: league.color)
                            .id(message.id)
                    }
                    if chatViewModel.isWaitingForReply {
                        TypingIndicatorView()
                            .id("typing")
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: chatViewModel.messages.count) { scrollToBottom(proxy) }
            .onChange(of: chatViewModel.isWaitingForReply) { scrollToBottom(proxy) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Text(league.emoji)
                .font(.system(size: 72))
            Text("Ask me anything \(league.displayName)")
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text("Games, scores and standings. Everything runs on your phone.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            VStack(spacing: 8) {
                ForEach(league.suggestions, id: \.self) { suggestion in
                    Button(suggestion) { currentTextInput = suggestion }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                }
            }
            .padding(.top, 8)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation {
            if chatViewModel.isWaitingForReply {
                proxy.scrollTo("typing", anchor: .bottom)
            } else {
                proxy.scrollTo(chatViewModel.messages.last?.id, anchor: .bottom)
            }
        }
    }
}
