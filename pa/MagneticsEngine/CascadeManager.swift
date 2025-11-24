//
//  CascadeManager.swift
//  POLARIS ARENA
//
//  Manages cascade effects when moves trigger additional reactions
//

import Foundation

/// A complete simulation step
struct SimulationStep {
    let stepNumber: Int
    let trigger: Coord?      // What triggered this step (nil for initial)
    let moves: [PendingMove]
    let ejections: [EjectionEvent]
}

/// Complete cascade result
struct CascadeResult {
    let steps: [SimulationStep]
    let finalBoard: Matrix5x5<Token>
    let totalEjections: [EjectionEvent]

    var chainLength: Int {
        return steps.count
    }

    var wasStable: Bool {
        return chainLength == 1  // Only initial placement, no cascades
    }
}

/// Manages cascade reactions
class CascadeManager {
    private let maxCascadeDepth: Int

    init(maxCascadeDepth: Int = 10) {
        self.maxCascadeDepth = maxCascadeDepth
    }

    /// Simulate complete cascade from initial placement
    func simulate(
        placement: Coord,
        token: Token,
        initialBoard: Matrix5x5<Token>
    ) -> CascadeResult {
        var board = initialBoard
        var steps: [SimulationStep] = []
        var allEjections: [EjectionEvent] = []

        // Place the initial token
        board[placement] = token

        // Solve initial forces
        let initialResult = OrderedSolver.solve(
            sourceCoord: placement,
            sourceType: token.type,
            board: board
        )

        // Apply moves to board
        for move in initialResult.moves {
            if let movingToken = board[move.from] {
                board[move.to] = movingToken
                board[move.from] = nil
            }
        }

        // Apply ejections
        for ejection in initialResult.ejections {
            board[ejection.from] = nil
            allEjections.append(ejection)
        }

        steps.append(SimulationStep(
            stepNumber: 0,
            trigger: placement,
            moves: initialResult.moves,
            ejections: initialResult.ejections
        ))

        // Check for cascades (tokens that moved might trigger new forces)
        var cascadeDepth = 1
        var triggersToCheck = Set(initialResult.moves.map { $0.to })

        while cascadeDepth < maxCascadeDepth && !triggersToCheck.isEmpty {
            var stepMoves: [PendingMove] = []
            var stepEjections: [EjectionEvent] = []

            // Collect ALL moves from ALL triggers first (without modifying board)
            for triggerCoord in triggersToCheck {
                guard let triggerToken = board[triggerCoord] else {
                    continue
                }

                let cascadeResult = OrderedSolver.solve(
                    sourceCoord: triggerCoord,
                    sourceType: triggerToken.type,
                    board: board
                )

                stepMoves.append(contentsOf: cascadeResult.moves)
                stepEjections.append(contentsOf: cascadeResult.ejections)
            }

            // If no moves, stop cascading
            if stepMoves.isEmpty && stepEjections.isEmpty {
                break
            }

            // Now apply ALL moves to the board
            var nextTriggers = Set<Coord>()
            for move in stepMoves {
                if let movingToken = board[move.from] {
                    board[move.to] = movingToken
                    board[move.from] = nil
                    nextTriggers.insert(move.to)
                }
            }

            // Apply ejections
            for ejection in stepEjections {
                board[ejection.from] = nil
                allEjections.append(ejection)
            }

            // Record step
            steps.append(SimulationStep(
                stepNumber: cascadeDepth,
                trigger: nil,  // Multiple triggers in cascade
                moves: stepMoves,
                ejections: stepEjections
            ))

            triggersToCheck = nextTriggers
            cascadeDepth += 1
        }

        return CascadeResult(
            steps: steps,
            finalBoard: board,
            totalEjections: allEjections
        )
    }

    /// Fast simulation without step tracking (for AI lookahead)
    func fastSimulate(
        placement: Coord,
        token: Token,
        initialBoard: Matrix5x5<Token>
    ) -> (board: Matrix5x5<Token>, ejections: [EjectionEvent]) {
        var board = initialBoard
        var allEjections: [EjectionEvent] = []

        // Place the initial token
        board[placement] = token

        // Solve initial forces
        var result = OrderedSolver.solve(
            sourceCoord: placement,
            sourceType: token.type,
            board: board
        )

        // Apply moves
        for move in result.moves {
            if let movingToken = board[move.from] {
                board[move.to] = movingToken
                board[move.from] = nil
            }
        }

        // Apply ejections
        for ejection in result.ejections {
            board[ejection.from] = nil
            allEjections.append(ejection)
        }

        // Quick cascade check
        var depth = 1
        var triggersToCheck = Set(result.moves.map { $0.to })

        while depth < maxCascadeDepth && !triggersToCheck.isEmpty {
            var cascadeMoves: [PendingMove] = []
            var cascadeEjections: [EjectionEvent] = []

            // Collect all cascades from all triggers (without modifying board)
            for coord in triggersToCheck {
                guard let token = board[coord] else { continue }

                let cascadeResult = OrderedSolver.solve(
                    sourceCoord: coord,
                    sourceType: token.type,
                    board: board
                )

                cascadeMoves.append(contentsOf: cascadeResult.moves)
                cascadeEjections.append(contentsOf: cascadeResult.ejections)
            }

            // If no cascades, stop
            if cascadeMoves.isEmpty && cascadeEjections.isEmpty {
                break
            }

            // Apply all moves
            var nextTriggers = Set<Coord>()
            for move in cascadeMoves {
                if let movingToken = board[move.from] {
                    board[move.to] = movingToken
                    board[move.from] = nil
                    nextTriggers.insert(move.to)
                }
            }

            // Apply ejections
            for ejection in cascadeEjections {
                board[ejection.from] = nil
                allEjections.append(ejection)
            }

            triggersToCheck = nextTriggers
            depth += 1
        }

        return (board, allEjections)
    }
}
