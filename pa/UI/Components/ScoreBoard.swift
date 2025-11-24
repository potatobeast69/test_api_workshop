//
//  ScoreBoard.swift
//  POLARIS ARENA
//
//  Score display component
//

import SwiftUI

struct ScoreBoard: View {
    let player1Score: Int
    let player2Score: Int
    let currentPlayer: Player
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 40) {
            // Player 1
            PlayerScore(
                score: player1Score,
                label: "P1",
                color: ColorPalette.tokenA,
                isActive: currentPlayer == .player1
            )

            // VS divider
            Text("—")
                .font(Typography.body)
                .foregroundColor(ColorPalette.text(for: colorScheme).opacity(0.3))

            // Player 2
            PlayerScore(
                score: player2Score,
                label: "P2",
                color: ColorPalette.tokenB,
                isActive: currentPlayer == .player2
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct PlayerScore: View {
    let score: Int
    let label: String
    let color: Color
    let isActive: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(Typography.caption)
                .foregroundColor(ColorPalette.textSecondary(for: colorScheme))

            Text("\(score)")
                .font(Typography.scoreMedium)
                .foregroundColor(isActive ? color : ColorPalette.text(for: colorScheme))
                .animation(.easeInOut(duration: Typography.animationFast), value: score)
                .animation(.easeInOut(duration: Typography.animationFast), value: isActive)
        }
        .opacity(isActive ? 1.0 : 0.6)
    }
}

#Preview {
    ZStack {
        ColorPalette.backgroundDark.ignoresSafeArea()
        ScoreBoard(
            player1Score: 5,
            player2Score: 3,
            currentPlayer: .player1
        )
    }
}
