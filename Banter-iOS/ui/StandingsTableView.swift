//
//  StandingsTableView.swift
//  Banter-iOS
//

import SwiftUI

/// A standings table, one section per conference or division.
/// Columns that a league lacks (points, draws) are simply left out.
struct StandingsTableView: View {
    let rows: [TeamStanding]
    var tint: Color = .accentColor

    private var groups: [(name: String, rows: [TeamStanding])] {
        var order: [String] = []
        var byGroup: [String: [TeamStanding]] = [:]
        for row in rows {
            if byGroup[row.group] == nil { order.append(row.group) }
            byGroup[row.group, default: []].append(row)
        }
        return order.map { ($0, byGroup[$0] ?? []) }
    }

    private var showsPoints: Bool { rows.contains { $0.points != nil } }
    private var showsDraws: Bool { rows.contains { ($0.ties ?? 0) > 0 } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(groups, id: \.name) { group in
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)
                        .textCase(.uppercase)

                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                        GridRow {
                            Text("#")
                            Text("Team")
                            Text("W")
                            if showsDraws { Text("D") }
                            Text("L")
                            if showsPoints { Text("Pts") }
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                        Divider().gridCellUnsizedAxes(.horizontal)

                        ForEach(Array(group.rows.enumerated()), id: \.offset) { index, row in
                            GridRow {
                                Text(row.rank.map(String.init) ?? "\(index + 1)")
                                    .foregroundStyle(.secondary)
                                Text(row.team)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(row.wins)")
                                if showsDraws { Text("\(row.ties ?? 0)") }
                                Text("\(row.losses)")
                                if showsPoints { Text("\(row.points ?? 0)").fontWeight(.semibold) }
                            }
                            .font(.caption)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
