//
//  OrderedSolver.swift
//  POLARIS ARENA
//
//  Deterministic force resolution: axial first, then diagonal
//

import Foundation

/// A pending move operation
struct PendingMove {
    let tokenId: UUID
    let from: Coord
    let to: Coord
    let priority: Int
}

/// An ejection event
struct EjectionEvent {
    let tokenId: UUID
    let from: Coord
    let owner: Player
}

/// Result of solving a turn's forces
struct SolverResult {
    let moves: [PendingMove]
    let ejections: [EjectionEvent]
    let conflicts: Int  // Number of resolved conflicts

    static let empty = SolverResult(moves: [], ejections: [], conflicts: 0)
}

/// Ordered force solver
class OrderedSolver {
    /// Solve all forces from a single source token placement
    static func solve(
        sourceCoord: Coord,
        sourceType: TokenType,
        board: Matrix5x5<Token>
    ) -> SolverResult {
        // Get all interactions
        let links = LocalField.interactions(
            from: sourceCoord,
            sourceType: sourceType,
            board: board
        )

        // Separate into axial and diagonal
        let axialLinks = links.filter { $0.direction.isAxial }
            .sorted { $0.priority > $1.priority }

        let diagonalLinks = links.filter { $0.direction.isDiagonal }
            .sorted { $0.priority > $1.priority }

        var moves: [PendingMove] = []
        var ejections: [EjectionEvent] = []
        var simulatedBoard = board
        var conflicts = 0

        // Process axial links first
        for link in axialLinks {
            let result = processLink(
                link: link,
                board: &simulatedBoard,
                moves: &moves,
                ejections: &ejections,
                conflicts: &conflicts
            )

            if result {
                // Link was processed
            }
        }

        // Then process diagonal links
        for link in diagonalLinks {
            let result = processLink(
                link: link,
                board: &simulatedBoard,
                moves: &moves,
                ejections: &ejections,
                conflicts: &conflicts
            )

            if result {
                // Link was processed
            }
        }

        return SolverResult(
            moves: moves,
            ejections: ejections,
            conflicts: conflicts
        )
    }

    /// Process a single link
    private static func processLink(
        link: MagneticLink,
        board: inout Matrix5x5<Token>,
        moves: inout [PendingMove],
        ejections: inout [EjectionEvent],
        conflicts: inout Int
    ) -> Bool {
        guard let forceResult = LocalField.calculateDisplacement(
            link: link,
            board: board
        ) else {
            return false
        }

        switch forceResult {
        case .moved(let from, let to):
            // Apply move to simulated board
            if let token = board[from] {
                moves.append(PendingMove(
                    tokenId: token.id,
                    from: from,
                    to: to,
                    priority: link.priority
                ))

                // Update simulated board
                board[to] = token
                board[from] = nil
                return true
            }

        case .ejected(let from):
            // Token ejected
            if let token = board[from] {
                ejections.append(EjectionEvent(
                    tokenId: token.id,
                    from: from,
                    owner: token.owner
                ))

                // Remove from simulated board
                board[from] = nil
                return true
            }

        case .chainPush(let chain):
            // Push entire chain
            return processChain(
                chain: chain,
                direction: link.direction,
                priority: link.priority,
                board: &board,
                moves: &moves,
                ejections: &ejections
            )

        case .blocked:
            conflicts += 1
            return false
        }

        return false
    }

    /// Process a chain push
    private static func processChain(
        chain: [Coord],
        direction: Direction,
        priority: Int,
        board: inout Matrix5x5<Token>,
        moves: inout [PendingMove],
        ejections: inout [EjectionEvent]
    ) -> Bool {
        // Process from end to start
        for coord in chain.reversed() {
            guard let token = board[coord] else { continue }

            let destination = coord.step(in: direction)

            if destination.isValid {
                // Move token
                moves.append(PendingMove(
                    tokenId: token.id,
                    from: coord,
                    to: destination,
                    priority: priority
                ))

                board[destination] = token
                board[coord] = nil
            } else {
                // Eject token
                ejections.append(EjectionEvent(
                    tokenId: token.id,
                    from: coord,
                    owner: token.owner
                ))

                board[coord] = nil
            }
        }

        return true
    }
}
