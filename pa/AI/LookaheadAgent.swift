//
//  LookaheadAgent.swift
//  POLARIS ARENA
//
//  AI agents with different difficulty levels
//

import Foundation

/// AI difficulty level
enum AIDifficulty {
    case reactive    // Simple: immediate threats only
    case tactical    // Medium: local evaluation
    case foresight   // Hard: 2-3 move lookahead

    var displayName: String {
        switch self {
        case .reactive: return "Reactive"
        case .tactical: return "Tactical"
        case .foresight: return "Foresight"
        }
    }
}

/// AI agent
class LookaheadAgent {
    let difficulty: AIDifficulty
    let player: Player
    private let cascadeManager = CascadeManager()

    init(difficulty: AIDifficulty, player: Player) {
        self.difficulty = difficulty
        self.player = player
    }

    /// Select best move
    func selectMove(board: Matrix5x5<Token>) -> AIMove? {
        switch difficulty {
        case .reactive:
            return selectReactiveMove(board: board)
        case .tactical:
            return selectTacticalMove(board: board)
        case .foresight:
            return selectForesightMove(board: board)
        }
    }

    // MARK: - Reactive AI

    /// Simple reactive strategy
    private func selectReactiveMove(board: Matrix5x5<Token>) -> AIMove? {
        let moves = MoveGen.generateMoves(for: player, board: board)

        // Pick first move that doesn't immediately lose tokens
        for move in moves {
            let token = Token(owner: player, type: move.tokenType)
            let result = cascadeManager.fastSimulate(
                placement: move.coord,
                token: token,
                initialBoard: board
            )

            let ownLosses = result.ejections.filter { $0.owner == player }.count
            if ownLosses == 0 {
                return move
            }
        }

        // Fallback: random safe move
        return moves.randomElement()
    }

    // MARK: - Tactical AI

    /// Tactical strategy with position evaluation
    private func selectTacticalMove(board: Matrix5x5<Token>) -> AIMove? {
        let moves = MoveGen.generatePrioritizedMoves(for: player, board: board)

        var bestMove: AIMove?
        var bestScore = Int.min

        for move in moves.prefix(15) {  // Evaluate top 15 moves
            let token = Token(owner: player, type: move.tokenType)
            let result = cascadeManager.fastSimulate(
                placement: move.coord,
                token: token,
                initialBoard: board
            )

            // Evaluate resulting position
            let positionScore = Heuristics.evaluate(
                board: result.board,
                for: player
            ).score

            let ejectionScore = Heuristics.evaluateEjections(
                ejections: result.ejections,
                for: player
            )

            let totalScore = positionScore + ejectionScore

            if totalScore > bestScore {
                bestScore = totalScore
                bestMove = move
            }
        }

        return bestMove ?? moves.first
    }

    // MARK: - Foresight AI

    /// Lookahead strategy (minimax-style)
    private func selectForesightMove(board: Matrix5x5<Token>) -> AIMove? {
        let moves = MoveGen.generatePrioritizedMoves(for: player, board: board)

        var bestMove: AIMove?
        var bestScore = Int.min

        for move in moves.prefix(10) {  // Evaluate top 10 moves
            let score = evaluateMoveWithLookahead(
                move: move,
                board: board,
                depth: 2,
                isMaximizing: true
            )

            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }

        return bestMove ?? moves.first
    }

    /// Recursive lookahead evaluation
    private func evaluateMoveWithLookahead(
        move: AIMove,
        board: Matrix5x5<Token>,
        depth: Int,
        isMaximizing: Bool
    ) -> Int {
        // Base case: simulate move
        let token = Token(
            owner: isMaximizing ? player : player.opponent,
            type: move.tokenType
        )

        let result = cascadeManager.fastSimulate(
            placement: move.coord,
            token: token,
            initialBoard: board
        )

        // Terminal evaluation
        if depth == 0 {
            let positionScore = Heuristics.evaluate(
                board: result.board,
                for: player
            ).score

            let ejectionScore = Heuristics.evaluateEjections(
                ejections: result.ejections,
                for: player
            )

            return positionScore + ejectionScore
        }

        // Recursive case
        let nextPlayer = isMaximizing ? player.opponent : player
        let nextMoves = MoveGen.generatePrioritizedMoves(
            for: nextPlayer,
            board: result.board
        )

        if isMaximizing {
            // Minimize opponent's best response
            var minScore = Int.max

            for nextMove in nextMoves.prefix(5) {
                let score = evaluateMoveWithLookahead(
                    move: nextMove,
                    board: result.board,
                    depth: depth - 1,
                    isMaximizing: false
                )
                minScore = min(minScore, score)
            }

            return minScore
        } else {
            // Maximize our response
            var maxScore = Int.min

            for nextMove in nextMoves.prefix(5) {
                let score = evaluateMoveWithLookahead(
                    move: nextMove,
                    board: result.board,
                    depth: depth - 1,
                    isMaximizing: true
                )
                maxScore = max(maxScore, score)
            }

            return maxScore
        }
    }
}
