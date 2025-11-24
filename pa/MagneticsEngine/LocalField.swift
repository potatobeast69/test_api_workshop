//
//  LocalField.swift
//  POLARIS ARENA
//
//  Calculates local magnetic field interactions
//

import Foundation

/// A magnetic interaction between two tokens
struct MagneticLink {
    let source: Coord        // Token causing the force
    let target: Coord        // Token being affected
    let direction: Direction
    let interaction: Interaction
    let priority: Int        // Higher = resolved first

    /// Mass/priority based on direction type and interaction
    static func calculatePriority(direction: Direction, interaction: Interaction) -> Int {
        var base = direction.isAxial ? 100 : 50  // Axial > diagonal

        // Repulsion slightly stronger than attraction
        if interaction == .repulsion {
            base += 10
        }

        return base
    }
}

/// Result of applying a force
enum ForceResult {
    case moved(from: Coord, to: Coord)
    case blocked                          // Target can't move (locked/anchored)
    case ejected(from: Coord)            // Pushed off board
    case chainPush([Coord])              // Multiple tokens pushed in line
}

/// Local field calculator
struct LocalField {
    /// Find all magnetic interactions from a source token
    static func interactions(
        from source: Coord,
        sourceType: TokenType,
        board: Matrix5x5<Token>
    ) -> [MagneticLink] {
        var links: [MagneticLink] = []

        // Check all 8 neighbors
        let neighbors = source.neighbors(axialOnly: false)

        for (direction, targetCoord) in neighbors {
            guard let targetToken = board[targetCoord] else { continue }

            let interaction = sourceType.interacts(with: targetToken.type)
            let priority = MagneticLink.calculatePriority(
                direction: direction,
                interaction: interaction
            )

            links.append(MagneticLink(
                source: source,
                target: targetCoord,
                direction: direction,
                interaction: interaction,
                priority: priority
            ))
        }

        return links
    }

    /// Calculate displacement for a single link
    static func calculateDisplacement(
        link: MagneticLink,
        board: Matrix5x5<Token>
    ) -> ForceResult? {
        guard let token = board[link.target] else { return nil }

        // Check if token can move
        if !token.canMove {
            return .blocked
        }

        switch link.interaction {
        case .repulsion:
            // Push target away from source
            return pushToken(
                at: link.target,
                in: link.direction,
                board: board
            )

        case .attraction:
            // Pull target toward source
            let pullDirection = link.direction.opposite
            return pullToken(
                at: link.target,
                toward: link.source,
                board: board
            )
        }
    }

    /// Push a token in a direction
    private static func pushToken(
        at coord: Coord,
        in direction: Direction,
        board: Matrix5x5<Token>
    ) -> ForceResult {
        let destination = coord.step(in: direction)

        // Check if destination is off-board
        if !destination.isValid {
            return .ejected(from: coord)
        }

        // Check if destination is occupied
        if board[destination] != nil {
            // Try to push the chain
            return pushChain(from: coord, in: direction, board: board)
        }

        // Simple move
        return .moved(from: coord, to: destination)
    }

    /// Push a chain of tokens
    private static func pushChain(
        from start: Coord,
        in direction: Direction,
        board: Matrix5x5<Token>
    ) -> ForceResult {
        var chain: [Coord] = [start]
        var current = start

        // Find all tokens in line
        while let next = current.neighbor(in: direction) {
            if board[next] != nil {
                chain.append(next)
                current = next
            } else {
                break
            }
        }

        // Check if any token in chain is immovable
        for coord in chain {
            if let token = board[coord], !token.canMove {
                return .blocked
            }
        }

        // Check if last token would go off-board
        if let last = chain.last {
            let lastDest = last.step(in: direction)
            if !lastDest.isValid {
                // Last token ejects, but we return the chain
                return .chainPush(chain)
            }
        }

        return .chainPush(chain)
    }

    /// Pull a token toward source
    private static func pullToken(
        at coord: Coord,
        toward source: Coord,
        board: Matrix5x5<Token>
    ) -> ForceResult {
        // Find direction from target to source
        guard let direction = coord.direction(to: source) else {
            return .blocked
        }

        let destination = coord.step(in: direction)

        // Destination must be valid and empty (or the source itself)
        if !destination.isValid {
            return .blocked
        }

        if destination == source {
            return .blocked  // Can't pull into source
        }

        if board[destination] != nil {
            return .blocked  // Can't pull into occupied space
        }

        return .moved(from: coord, to: destination)
    }
}
