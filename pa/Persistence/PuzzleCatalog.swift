//
//  PuzzleCatalog.swift
//  POLARIS ARENA
//
//  Puzzle definitions and catalog
//

import Foundation

/// A puzzle challenge
struct Puzzle: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let difficulty: Int  // 1-5
    let initialBoard: PuzzleBoard
    let objective: PuzzleObjective

    var isCompleted: Bool {
        return LocalStore.shared.isPuzzleCompleted(id)
    }
}

/// Simplified board state for puzzles
struct PuzzleBoard: Codable {
    struct PuzzleToken: Codable {
        let coord: Coord
        let owner: Player
        let type: TokenType
        let isLocked: Bool
    }

    let tokens: [PuzzleToken]

    /// Convert to game board
    func toGameBoard() -> Matrix5x5<Token> {
        var board = Matrix5x5<Token>()
        for puzzleToken in tokens {
            let token = Token(
                owner: puzzleToken.owner,
                type: puzzleToken.type
            )
            var mutableToken = token
            mutableToken.isLocked = puzzleToken.isLocked
            board[puzzleToken.coord] = mutableToken
        }
        return board
    }
}

/// Puzzle objective
enum PuzzleObjective: Codable {
    case ejectNTokens(count: Int, maxMoves: Int)
    case clearBoard(maxMoves: Int)
    case achieveScore(target: Int, maxMoves: Int)
    case createCascade(minLength: Int, maxMoves: Int)

    var displayText: String {
        switch self {
        case .ejectNTokens(let count, let maxMoves):
            return "Eject \(count) tokens in \(maxMoves) moves"
        case .clearBoard(let maxMoves):
            return "Clear the board in \(maxMoves) moves"
        case .achieveScore(let target, let maxMoves):
            return "Score \(target) points in \(maxMoves) moves"
        case .createCascade(let minLength, let maxMoves):
            return "Create a cascade of \(minLength)+ steps in \(maxMoves) moves"
        }
    }
}

/// Puzzle catalog
class PuzzleCatalog {
    static let shared = PuzzleCatalog()

    private init() {}

    /// Get all puzzles
    func getAllPuzzles() -> [Puzzle] {
        return [
            createPuzzle1(),
            createPuzzle2(),
            createPuzzle3()
        ]
    }

    /// Get puzzle by ID
    func getPuzzle(id: String) -> Puzzle? {
        return getAllPuzzles().first { $0.id == id }
    }

    // MARK: - Puzzle Definitions

    private func createPuzzle1() -> Puzzle {
        let tokens = [
            PuzzleBoard.PuzzleToken(
                coord: Coord(row: 2, col: 2),
                owner: .player2,
                type: .A,
                isLocked: true
            ),
            PuzzleBoard.PuzzleToken(
                coord: Coord(row: 2, col: 3),
                owner: .player2,
                type: .A,
                isLocked: false
            )
        ]

        return Puzzle(
            id: "puzzle_001",
            title: "First Push",
            description: "Learn the basics of repulsion. Eject the movable token.",
            difficulty: 1,
            initialBoard: PuzzleBoard(tokens: tokens),
            objective: .ejectNTokens(count: 1, maxMoves: 1)
        )
    }

    private func createPuzzle2() -> Puzzle {
        let tokens = [
            PuzzleBoard.PuzzleToken(
                coord: Coord(row: 1, col: 2),
                owner: .player2,
                type: .A,
                isLocked: false
            ),
            PuzzleBoard.PuzzleToken(
                coord: Coord(row: 2, col: 2),
                owner: .player2,
                type: .B,
                isLocked: false
            ),
            PuzzleBoard.PuzzleToken(
                coord: Coord(row: 3, col: 2),
                owner: .player2,
                type: .A,
                isLocked: false
            )
        ]

        return Puzzle(
            id: "puzzle_002",
            title: "Attract & Push",
            description: "Use attraction to pull, then repulsion to push.",
            difficulty: 2,
            initialBoard: PuzzleBoard(tokens: tokens),
            objective: .ejectNTokens(count: 2, maxMoves: 2)
        )
    }

    private func createPuzzle3() -> Puzzle {
        let tokens = [
            PuzzleBoard.PuzzleToken(
                coord: Coord(row: 0, col: 0),
                owner: .player2,
                type: .A,
                isLocked: false
            ),
            PuzzleBoard.PuzzleToken(
                coord: Coord(row: 0, col: 1),
                owner: .player2,
                type: .A,
                isLocked: false
            ),
            PuzzleBoard.PuzzleToken(
                coord: Coord(row: 1, col: 1),
                owner: .player2,
                type: .B,
                isLocked: false
            )
        ]

        return Puzzle(
            id: "puzzle_003",
            title: "Chain Reaction",
            description: "Create a cascade that clears all tokens.",
            difficulty: 3,
            initialBoard: PuzzleBoard(tokens: tokens),
            objective: .createCascade(minLength: 2, maxMoves: 2)
        )
    }
}
