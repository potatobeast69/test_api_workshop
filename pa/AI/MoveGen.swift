//
//  MoveGen.swift
//  POLARIS ARENA
//
//  Generate possible moves for AI
//

import Foundation

/// A possible move
struct AIMove {
    let coord: Coord
    let tokenType: TokenType

    /// Unique identifier for move comparison
    var id: String {
        return "\(coord.notation)-\(tokenType.rawValue)"
    }
}

/// Move generator for AI
struct MoveGen {
    /// Generate all legal moves for a player
    static func generateMoves(
        for player: Player,
        board: Matrix5x5<Token>
    ) -> [AIMove] {
        var moves: [AIMove] = []

        // Find all empty cells
        for coord in Matrix5x5<Token>.allCoords() {
            if board[coord] == nil {
                // Can place either A or B
                moves.append(AIMove(coord: coord, tokenType: .A))
                moves.append(AIMove(coord: coord, tokenType: .B))
            }
        }

        return moves
    }

    /// Generate prioritized moves (for smarter AI)
    static func generatePrioritizedMoves(
        for player: Player,
        board: Matrix5x5<Token>
    ) -> [AIMove] {
        let allMoves = generateMoves(for: player, board: board)

        // Sort by strategic value
        return allMoves.sorted { move1, move2 in
            let score1 = quickEvaluate(move: move1, board: board)
            let score2 = quickEvaluate(move: move2, board: board)
            return score1 > score2
        }
    }

    /// Quick evaluation of move quality (without full simulation)
    private static func quickEvaluate(move: AIMove, board: Matrix5x5<Token>) -> Int {
        var score = 0

        // Center is valuable
        if move.coord.isCenter {
            score += 50
        } else if move.coord.distance(to: Coord(row: 2, col: 2)) == 1 {
            score += 30  // Near center
        }

        // Count neighbors
        let neighbors = move.coord.neighbors()
        let neighborCount = neighbors.values.compactMap { board[$0] }.count

        // Some neighbors = good for interactions
        score += neighborCount * 10

        // Edge positions are risky
        if move.coord.isEdge {
            score -= 20
        }

        return score
    }
}
