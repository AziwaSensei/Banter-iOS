//
//  MatchupsTableView.swift
//  Banter-iOS
//

import SwiftUI

/// This week's games: who plays whom, and either the score or the start time.
struct MatchupsTableView: View {
    let rows: [Matchup]
    var tint: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("This week")
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .textCase(.uppercase)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, game in
                    GridRow {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(game.awayTeam)
                            Text(game.homeTeam)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if game.completed {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(game.awayScore ?? "-")
                                Text(game.homeScore ?? "-")
                            }
                            .fontWeight(.semibold)
                            .monospacedDigit()
                        } else {
                            Text(startTime(for: game))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .font(.caption)
                    .lineLimit(1)

                    Divider().gridCellUnsizedAxes(.horizontal)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func startTime(for game: Matchup) -> String {
        guard let date = game.date else { return game.statusDetail }
        return date.formatted(.dateTime.weekday(.abbreviated).hour().minute())
    }
}
