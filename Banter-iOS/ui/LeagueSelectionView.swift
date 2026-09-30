//
//  LeagueSelectionView.swift
//  Banter-iOS
//

import SwiftUI

struct LeagueSelectionView: View {
    @Environment(ChatViewModel.self) private var chatViewModel

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Banter")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                    Text("Pick a league. Then ask away.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(League.allCases) { league in
                        LeagueCard(league: league) {
                            chatViewModel.select(league)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
    }
}

/// A big tappable tile with the league's emoji and colour.
private struct LeagueCard: View {
    let league: League
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Text(league.emoji)
                    .font(.system(size: 44))
                Spacer(minLength: 0)
                Text(league.displayName)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
            .background(league.gradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: league.color.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(PressableStyle())
    }
}

/// Shrinks a little while pressed. Small, but it makes the tiles feel alive.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
