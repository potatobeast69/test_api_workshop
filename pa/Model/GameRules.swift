//
//  GameRules.swift
//  POLARIS ARENA
//
//  Core game rules, validation, and end conditions
//

import Foundation

/// Game configuration
struct GameConfig {
    let maxTurns: Int
    let startingEnergy: Int
    let energyPerTurn: Int
    let energyPerEjection: Int  // Per 2 ejections

    static let standard = GameConfig(
        maxTurns: 20,
        startingEnergy: 0,
        energyPerTurn: 1,
        energyPerEjection: 1  // +1 per 2 ejections
    )
}

/// Scoring events
enum ScoringEvent {
    case ejectOpponent     // +1
    case loseOwn          // -1
    case stableTetra      // +2 (4 tokens in stable formation)
    case controlCenter    // +1 (at game end)
}

struct ScoreChange {
    let player: Player
    let event: ScoringEvent
    let amount: Int

    static func ejectOpponent(by player: Player) -> ScoreChange {
        return ScoreChange(player: player, event: .ejectOpponent, amount: 1)
    }

    static func loseOwn(player: Player) -> ScoreChange {
        return ScoreChange(player: player, event: .loseOwn, amount: -1)
    }

    static func stableTetra(player: Player) -> ScoreChange {
        return ScoreChange(player: player, event: .stableTetra, amount: 2)
    }

    static func controlCenter(player: Player) -> ScoreChange {
        return ScoreChange(player: player, event: .controlCenter, amount: 1)
    }
}

/// Game end condition
enum EndCondition {
    case maxTurnsReached
    case playerEliminated(Player)  // No tokens remaining
    case resignation(Player)

    var winner: Player? {
        switch self {
        case .playerEliminated(let loser):
            return loser.opponent
        case .resignation(let resigner):
            return resigner.opponent
        case .maxTurnsReached:
            return nil  // Determined by score
        }
    }
}

/// Game rules engine
struct GameRules {
    let config: GameConfig

    init(config: GameConfig = .standard) {
        self.config = config
    }

    /// Check if a placement is valid
    func isValidPlacement(at coord: Coord, in board: Matrix5x5<Token>) -> Bool {
        // Must be within bounds
        guard coord.isValid else { return false }

        // Cell must be empty
        return board[coord] == nil
    }

    /// Calculate score changes for ejected tokens
    func scoreChangesForEjection(tokens: [Token]) -> [ScoreChange] {
        var changes: [ScoreChange] = []

        for token in tokens {
            // Owner loses point
            changes.append(.loseOwn(player: token.owner))

            // Opponent gains point
            changes.append(.ejectOpponent(by: token.owner.opponent))
        }

        return changes
    }

    /// Check for stable tetras (simplified: 4 tokens in 2x2 formation)
    func findStableTetras(in board: Matrix5x5<Token>, for player: Player) -> [ScoreChange] {
        var changes: [ScoreChange] = []

        // Check all possible 2x2 squares
        for row in 0..<4 {
            for col in 0..<4 {
                let coords = [
                    Coord(row: row, col: col),
                    Coord(row: row, col: col + 1),
                    Coord(row: row + 1, col: col),
                    Coord(row: row + 1, col: col + 1)
                ]

                // Check if all 4 positions belong to player
                let tokens = coords.compactMap { board[$0] }
                if tokens.count == 4 && tokens.allSatisfy({ $0.owner == player }) {
                    changes.append(.stableTetra(player: player))
                }
            }
        }

        return changes
    }

    /// Check if center is controlled
    func centerControl(in board: Matrix5x5<Token>) -> Player? {
        let center = Coord(row: 2, col: 2)
        return board[center]?.owner
    }

    /// Check for end condition
    func checkEndCondition(turnCount: Int, board: Matrix5x5<Token>) -> EndCondition? {
        // Max turns reached
        if turnCount >= config.maxTurns {
            return .maxTurnsReached
        }

        // Check if any player has no tokens
        // IMPORTANT: Only eliminate if both players have placed at least one token
        // (turnCount > 2 means both players had at least one turn)
        if turnCount > 2 {
            var p1Count = 0
            var p2Count = 0

            for coord in Matrix5x5<Token>.allCoords() {
                if let token = board[coord] {
                    if token.owner == .player1 {
                        p1Count += 1
                    } else {
                        p2Count += 1
                    }
                }
            }

            if p1Count == 0 {
                return .playerEliminated(.player1)
            }
            if p2Count == 0 {
                return .playerEliminated(.player2)
            }
        }

        return nil
    }

    /// Calculate final winner based on scores
    func determineWinner(player1Score: Int, player2Score: Int, board: Matrix5x5<Token>) -> Player? {
        var finalP1 = player1Score
        var finalP2 = player2Score

        // Add center control bonus
        if let centerOwner = centerControl(in: board) {
            if centerOwner == .player1 {
                finalP1 += 1
            } else {
                finalP2 += 1
            }
        }

        if finalP1 > finalP2 {
            return .player1
        } else if finalP2 > finalP1 {
            return .player2
        } else {
            return nil  // Draw
        }
    }
}
