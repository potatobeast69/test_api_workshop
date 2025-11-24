//
//  Heuristics.swift
//  POLARIS ARENA
//
//  Position evaluation heuristics for AI
//

import Foundation

/// Board evaluation metrics
struct BoardEvaluation {
    let player: Player
    let score: Int

    // Components
    let tokenCount: Int
    let centerControl: Int
    let stability: Int
    let risk: Int
}

/// Heuristic evaluator
struct Heuristics {
    /// Evaluate board position for a player
    static func evaluate(
        board: Matrix5x5<Token>,
        for player: Player
    ) -> BoardEvaluation {
        let tokenCount = countTokens(board: board, for: player)
        let centerControl = evaluateCenterControl(board: board, for: player)
        let stability = evaluateStability(board: board, for: player)
        let risk = evaluateRisk(board: board, for: player)

        // Weighted sum
        let totalScore = (tokenCount * 10) + (centerControl * 30) + (stability * 20) - (risk * 15)

        return BoardEvaluation(
            player: player,
            score: totalScore,
            tokenCount: tokenCount,
            centerControl: centerControl,
            stability: stability,
            risk: risk
        )
    }

    /// Count player's tokens
    private static func countTokens(board: Matrix5x5<Token>, for player: Player) -> Int {
        var count = 0
        for coord in Matrix5x5<Token>.allCoords() {
            if let token = board[coord], token.owner == player {
                count += 1
            }
        }
        return count
    }

    /// Evaluate center control
    private static func evaluateCenterControl(board: Matrix5x5<Token>, for player: Player) -> Int {
        let center = Coord(row: 2, col: 2)
        var score = 0

        // Control center = high value
        if let centerToken = board[center], centerToken.owner == player {
            score += 100
        }

        // Control near-center squares
        let nearCenter = [
            Coord(row: 1, col: 2),
            Coord(row: 2, col: 1),
            Coord(row: 2, col: 3),
            Coord(row: 3, col: 2)
        ]

        for coord in nearCenter {
            if let token = board[coord], token.owner == player {
                score += 20
            }
        }

        return score
    }

    /// Evaluate position stability (tokens not at risk)
    private static func evaluateStability(board: Matrix5x5<Token>, for player: Player) -> Int {
        var stability = 0

        for coord in Matrix5x5<Token>.allCoords() {
            guard let token = board[coord], token.owner == player else { continue }

            // Distance from edge = stability
            let edgeDistance = min(
                coord.row,
                coord.col,
                4 - coord.row,
                4 - coord.col
            )

            stability += edgeDistance * 10

            // Surrounded by own tokens = stable
            let neighbors = coord.neighbors()
            let ownNeighbors = neighbors.values.compactMap { board[$0] }
                .filter { $0.owner == player }
                .count

            stability += ownNeighbors * 5
        }

        return stability
    }

    /// Evaluate risk (tokens near edge or threatened)
    private static func evaluateRisk(board: Matrix5x5<Token>, for player: Player) -> Int {
        var risk = 0

        for coord in Matrix5x5<Token>.allCoords() {
            guard let token = board[coord], token.owner == player else { continue }

            // Edge proximity = risk
            if coord.isEdge {
                risk += 30
            }

            // Check if any neighbor is opponent token
            let neighbors = coord.neighbors()
            for (direction, neighborCoord) in neighbors {
                if let neighborToken = board[neighborCoord], neighborToken.owner != player {
                    // Opponent token nearby
                    let interaction = token.type.interacts(with: neighborToken.type)

                    if interaction == .repulsion {
                        // Opponent could push us
                        risk += 15
                    }

                    // Check if we're near edge in push direction
                    if let beyondCoord = coord.neighbor(in: direction),
                       !beyondCoord.isValid {
                        risk += 25  // One push from ejection
                    }
                }
            }
        }

        return risk
    }

    /// Evaluate expected ejections from a move
    static func evaluateEjections(
        ejections: [EjectionEvent],
        for player: Player
    ) -> Int {
        var score = 0

        for ejection in ejections {
            if ejection.owner == player {
                score -= 30  // Lost our token
            } else {
                score += 50  // Ejected opponent
            }
        }

        return score
    }
}
