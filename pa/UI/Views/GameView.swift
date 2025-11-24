//
//  GameView.swift
//  POLARIS ARENA
//
//  Main game view
//

import SwiftUI

struct GameView: View {
    let gameMode: GameMode
    @StateObject private var match = MatchLoop()
    @State private var selectedCoord: Coord?
    @State private var selectedTokenType: TokenType = .A
    @State private var aiDifficulty: AIDifficulty = .tactical
    @State private var aiTaskScheduled = false
    @State private var showEndGameScreen = false
    @State private var humanPlayer: Player = .player1  // Which player is human
    @State private var showPlayerSelection = true
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    private var isAIEnabled: Bool {
        return gameMode == .soloArena || gameMode == .practice
    }

    private var aiPlayer: Player {
        return humanPlayer.opponent
    }

    var body: some View {
        ZStack {
            // Background
            ColorPalette.background(for: colorScheme)
                .ignoresSafeArea()

            // Player selection screen (AI mode only)
            if isAIEnabled && showPlayerSelection {
                PlayerSelectionView(
                    humanPlayer: $humanPlayer,
                    onStart: {
                        showPlayerSelection = false
                        match.start()
                        // If AI goes first, trigger AI move
                        if humanPlayer == .player2 {
                            triggerAIMove()
                        }
                    }
                )
            } else {
                gameContent
            }

            // End game overlay
            if showEndGameScreen, let result = match.matchResult {
                EndGameView(
                    result: result,
                    humanPlayer: isAIEnabled ? humanPlayer : nil,
                    onPlayAgain: {
                        showEndGameScreen = false
                        match.reset()
                        if isAIEnabled {
                            showPlayerSelection = true
                        } else {
                            match.start()
                        }
                    },
                    onMainMenu: {
                        dismiss()
                    }
                )
            }
        }
        .navigationBarBackButtonHidden(false)
        .onAppear {
            if !isAIEnabled {
                showPlayerSelection = false
                match.start()
            }
        }
        .onChange(of: match.state) { oldValue, newValue in
            if newValue == .finished {
                showEndGameScreen = true
                // Save statistics
                saveStatistics()
            }
        }
        .onChange(of: match.currentPlayer) { oldValue, newValue in
            // AI auto-play for Solo Arena mode
            if isAIEnabled && newValue == aiPlayer && match.state == .playing && !aiTaskScheduled {
                triggerAIMove()
            }
        }
    }

    private var gameContent: some View {
        VStack(spacing: 0) {
                // Top bar: Score and turn info
                VStack(spacing: 12) {
                    ScoreBoard(
                        player1Score: match.player1Score,
                        player2Score: match.player2Score,
                        currentPlayer: match.currentPlayer
                    )

                    HStack(spacing: 16) {
                        // Turn counter
                        Text("Turn \(match.turnNumber)/20")
                            .font(Typography.caption)
                            .foregroundColor(ColorPalette.textSecondary(for: colorScheme))

                        // Energy display
                        EnergyBar(
                            currentEnergy: match.currentPlayerEnergy().current,
                            maxEnergy: match.currentPlayerEnergy().maximum,
                            player: match.currentPlayer
                        )
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)

                Spacer()

                // Game board (placeholder - would use MetalKit rendering)
                GridView(
                    board: match.board,
                    onCellTapped: { coord in
                        handleCellTap(coord)
                    }
                )
                .frame(maxWidth: .infinity)
                .aspectRatio(1.0, contentMode: .fit)
                .padding(20)

                // Token type selector
                if match.state == .playing {
                    TokenTypeSelector(
                        selectedType: $selectedTokenType,
                        playerColor: match.currentPlayer == .player1
                            ? ColorPalette.tokenA
                            : ColorPalette.tokenB
                    )
                    .padding(.horizontal, 20)
                }

                Spacer()

                // Action toolbar
                ActionToolbar(
                    onUndo: {
                        // Undo last move
                    },
                    onMenu: {
                        // Show menu / go back
                        dismiss()
                    },
                    canUndo: false
                )
            }
    }

    // MARK: - AI Logic

    private func triggerAIMove() {
        guard !aiTaskScheduled else { return }

        print("🤖 AI turn starting...")
        aiTaskScheduled = true

        // Small delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Double-check conditions before executing
            guard match.state == .playing && match.currentPlayer == aiPlayer else {
                aiTaskScheduled = false
                return
            }

            let ai = LookaheadAgent(difficulty: aiDifficulty, player: aiPlayer)

            if let move = ai.selectMove(board: match.board) {
                print("🤖 AI chose: \(move.coord.notation) with \(move.tokenType)")

                withAnimation(.easeInOut(duration: 0.18)) {
                    let action = TurnAction.placement(
                        coord: move.coord,
                        tokenType: move.tokenType
                    )
                    _ = match.executeTurn(action: action)

                    // Reset flag after AI move completes
                    aiTaskScheduled = false
                }
            } else {
                print("🤖 AI has no valid moves!")
                aiTaskScheduled = false
            }
        }
    }

    // MARK: - Statistics

    private func saveStatistics() {
        guard let result = match.matchResult else { return }

        let humanScore: Int
        let didWin: Bool
        let isDraw: Bool

        if isAIEnabled {
            // AI mode - check if human won
            humanScore = humanPlayer == .player1 ? result.player1Score : result.player2Score
            if let winner = result.winner {
                didWin = (winner == humanPlayer)
                isDraw = false
            } else {
                didWin = false
                isDraw = true
            }
        } else {
            // Duel mode - player 1 perspective
            humanScore = result.player1Score
            if let winner = result.winner {
                didWin = (winner == .player1)
                isDraw = false
            } else {
                didWin = false
                isDraw = true
            }
        }

        // Count ejections for human player
        let ejections = 0 // We'd need to track this separately if needed

        StatisticsManager.shared.recordGame(
            mode: gameMode,
            didWin: didWin,
            isDraw: isDraw,
            playerScore: humanScore,
            totalTurns: result.totalTurns,
            ejections: ejections
        )
    }

    // MARK: - User Input

    private func handleCellTap(_ coord: Coord) {
        guard match.state == .playing else {
            print("⚠️ Game not playing, state: \(match.state)")
            return
        }

        // In AI mode, only allow human player to tap
        if isAIEnabled && match.currentPlayer != humanPlayer {
            print("⚠️ Not your turn! Current player: \(match.currentPlayer), Human: \(humanPlayer)")
            return
        }

        print("🎯 Tapped: \(coord.notation)")

        // Try to place token
        if match.board[coord] == nil {
            print("✅ Cell empty, placing \(selectedTokenType) for \(match.currentPlayer)")
            let action = TurnAction.placement(coord: coord, tokenType: selectedTokenType)

            withAnimation(.easeInOut(duration: 0.18)) {
                if let result = match.executeTurn(action: action) {
                    print("🎮 Turn executed! Ejections: \(result.cascadeResult?.totalEjections.count ?? 0)")
                    HapticsManager.shared.tokenPlaced()

                    // Trigger haptics for cascade
                    if let cascade = result.cascadeResult, cascade.chainLength > 1 {
                        HapticsManager.shared.cascade(length: cascade.chainLength)
                    }

                    print("📊 Score: P1=\(match.player1Score), P2=\(match.player2Score)")
                    print("🔄 Turn: \(match.turnNumber), Current: \(match.currentPlayer)")
                } else {
                    print("❌ Turn execution failed!")
                }
            }
        } else {
            print("⚠️ Cell occupied at \(coord.notation)")
        }
    }
}

/// Simple grid visualization (simplified version)
struct GridView: View {
    let board: Matrix5x5<Token>
    let onCellTapped: (Coord) -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geometry in
            let cellSize = geometry.size.width / 5

            ZStack(alignment: .topLeading) {
                // Grid lines
                GridLines(cells: 5)
                    .stroke(ColorPalette.grid(for: colorScheme), lineWidth: 1)

                // Tokens and tap areas
                ForEach(0..<5, id: \.self) { row in
                    ForEach(0..<5, id: \.self) { col in
                        let coord = Coord(row: row, col: col)

                        ZStack {
                            // Tap area (always present)
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onCellTapped(coord)
                                }

                            // Token (if present)
                            if let token = board[coord] {
                                TokenView(token: token)
                                    .frame(width: cellSize * 0.7, height: cellSize * 0.7)
                                    .transition(.scale.combined(with: .opacity))
                                    .id(token.id)
                            }
                        }
                        .frame(width: cellSize, height: cellSize)
                        .offset(
                            x: CGFloat(col) * cellSize,
                            y: CGFloat(row) * cellSize
                        )
                    }
                }
            }
        }
    }
}

struct GridLines: Shape {
    let cells: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cellSize = rect.width / CGFloat(cells)

        // Horizontal lines
        for i in 0...cells {
            let y = CGFloat(i) * cellSize
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }

        // Vertical lines
        for i in 0...cells {
            let x = CGFloat(i) * cellSize
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }

        return path
    }
}

struct TokenView: View {
    let token: Token

    var body: some View {
        Circle()
            .fill(playerColor)
            .overlay(
                Circle()
                    .stroke(typeIndicatorColor, lineWidth: 3)
            )
            .shadow(color: playerColor.opacity(0.5), radius: 8)
    }

    private var playerColor: Color {
        // Color based on player (owner)
        return token.owner == .player1 ? ColorPalette.tokenA : ColorPalette.tokenB
    }

    private var typeIndicatorColor: Color {
        // Border indicates token type (A or B)
        return token.type == .A ? Color.white.opacity(0.8) : Color.black.opacity(0.5)
    }
}

struct TokenTypeSelector: View {
    @Binding var selectedType: TokenType
    let playerColor: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 20) {
            TokenTypeButton(
                type: .A,
                isSelected: selectedType == .A,
                action: { selectedType = .A }
            )

            TokenTypeButton(
                type: .B,
                isSelected: selectedType == .B,
                action: { selectedType = .B }
            )
        }
        .padding(.vertical, 12)
    }
}

struct TokenTypeButton: View {
    let type: TokenType
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: {
            HapticsManager.shared.selection()
            action()
        }) {
            VStack(spacing: 8) {
                Circle()
                    .fill(tokenColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? Color.white : Color.clear,
                                lineWidth: 3
                            )
                    )

                Text(type.rawValue)
                    .font(Typography.caption)
                    .foregroundColor(ColorPalette.text(for: colorScheme))
            }
        }
        .opacity(isSelected ? 1.0 : 0.5)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: Typography.animationFast), value: isSelected)
    }

    private var tokenColor: Color {
        return type == .A ? ColorPalette.tokenA : ColorPalette.tokenB
    }
}

// MARK: - Player Selection View

struct PlayerSelectionView: View {
    @Binding var humanPlayer: Player
    let onStart: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 40) {
            Text("Choose Your Color")
                .font(Typography.title)
                .foregroundColor(ColorPalette.text(for: colorScheme))

            HStack(spacing: 30) {
                // Red (Player 1)
                PlayerColorButton(
                    color: ColorPalette.tokenA,
                    label: "Red",
                    sublabel: "Play First",
                    isSelected: humanPlayer == .player1,
                    action: {
                        humanPlayer = .player1
                    }
                )

                // Green (Player 2)
                PlayerColorButton(
                    color: ColorPalette.tokenB,
                    label: "Green",
                    sublabel: "Play Second",
                    isSelected: humanPlayer == .player2,
                    action: {
                        humanPlayer = .player2
                    }
                )
            }

            Button(action: onStart) {
                Text("Start Game")
                    .font(Typography.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(ColorPalette.tokenA)
                    .cornerRadius(12)
            }
            .padding(.top, 20)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ColorPalette.background(for: colorScheme).opacity(0.95))
                .shadow(radius: 20)
        )
        .padding(40)
    }
}

struct PlayerColorButton: View {
    let color: Color
    let label: String
    let sublabel: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: {
            HapticsManager.shared.selection()
            action()
        }) {
            VStack(spacing: 16) {
                Circle()
                    .fill(color)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 4)
                    )
                    .shadow(color: color.opacity(0.5), radius: 10)

                VStack(spacing: 4) {
                    Text(label)
                        .font(Typography.body)
                        .foregroundColor(ColorPalette.text(for: colorScheme))

                    Text(sublabel)
                        .font(Typography.caption)
                        .foregroundColor(ColorPalette.textSecondary(for: colorScheme))
                }
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - End Game View

struct EndGameView: View {
    let result: MatchResult
    let humanPlayer: Player?  // nil for PvP
    let onPlayAgain: () -> Void
    let onMainMenu: () -> Void
    @Environment(\.colorScheme) var colorScheme

    private var didHumanWin: Bool? {
        guard let humanPlayer = humanPlayer, let winner = result.winner else {
            return nil
        }
        return winner == humanPlayer
    }

    private var resultTitle: String {
        if let didHumanWin = didHumanWin {
            return didHumanWin ? "Victory!" : "Defeat"
        } else if let winner = result.winner {
            return "\(winner == .player1 ? "Red" : "Green") Wins!"
        } else {
            return "Draw!"
        }
    }

    private var resultColor: Color {
        if let didHumanWin = didHumanWin {
            return didHumanWin ? ColorPalette.tokenA : ColorPalette.tokenB
        } else if let winner = result.winner {
            return winner == .player1 ? ColorPalette.tokenA : ColorPalette.tokenB
        } else {
            return .gray
        }
    }

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { }  // Prevent tap-through

            VStack(spacing: 30) {
                // Result title
                Text(resultTitle)
                    .font(Typography.scoreLarge)
                    .foregroundColor(resultColor)

                // Scores
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(ColorPalette.tokenA)
                            .frame(width: 40, height: 40)
                        Text("\(result.player1Score)")
                            .font(Typography.scoreMedium)
                            .foregroundColor(ColorPalette.text(for: colorScheme))
                        Text("Red")
                            .font(Typography.caption)
                            .foregroundColor(ColorPalette.textSecondary(for: colorScheme))
                    }

                    Text(":")
                        .font(Typography.scoreMedium)
                        .foregroundColor(ColorPalette.text(for: colorScheme))

                    VStack(spacing: 8) {
                        Circle()
                            .fill(ColorPalette.tokenB)
                            .frame(width: 40, height: 40)
                        Text("\(result.player2Score)")
                            .font(Typography.scoreMedium)
                            .foregroundColor(ColorPalette.text(for: colorScheme))
                        Text("Green")
                            .font(Typography.caption)
                            .foregroundColor(ColorPalette.textSecondary(for: colorScheme))
                    }
                }

                // Game stats
                VStack(spacing: 8) {
                    Text("Total Turns: \(result.totalTurns)")
                        .font(Typography.body)
                        .foregroundColor(ColorPalette.textSecondary(for: colorScheme))

                    Text(endConditionText)
                        .font(Typography.caption)
                        .foregroundColor(ColorPalette.textSecondary(for: colorScheme))
                }
                .padding(.top, 10)

                // Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        HapticsManager.shared.selection()
                        onMainMenu()
                    }) {
                        Text("Main Menu")
                            .font(Typography.body)
                            .foregroundColor(ColorPalette.text(for: colorScheme))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(ColorPalette.textSecondary(for: colorScheme).opacity(0.3))
                            .cornerRadius(10)
                    }

                    Button(action: {
                        HapticsManager.shared.selection()
                        onPlayAgain()
                    }) {
                        Text("Play Again")
                            .font(Typography.body)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(resultColor)
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 10)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(ColorPalette.background(for: colorScheme))
                    .shadow(radius: 30)
            )
            .padding(40)
        }
    }

    private var endConditionText: String {
        switch result.endCondition {
        case .maxTurnsReached:
            return "Game ended after 20 turns"
        case .playerEliminated(let player):
            return "\(player == .player1 ? "Red" : "Green") eliminated"
        case .resignation(let player):
            return "\(player == .player1 ? "Red" : "Green") resigned"
        }
    }
}

#Preview {
    GameView(gameMode: .duel)
        .preferredColorScheme(.dark)
}
