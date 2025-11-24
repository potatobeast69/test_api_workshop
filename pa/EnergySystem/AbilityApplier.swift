//
//  AbilityApplier.swift
//  POLARIS ARENA
//
//  Applies abilities to game state
//

import Foundation

/// Applies abilities atomically
class AbilityApplier {
    /// Apply an ability to the board
    static func apply(
        _ request: AbilityRequest,
        to board: inout Matrix5x5<Token>
    ) -> AbilityResult {
        switch request.ability {
        case .polarFlip:
            return applyPolarFlip(target: request.target, player: request.player, board: &board)

        case .vectorKick:
            return applyVectorKick(target: request.target, player: request.player, board: &board)

        case .fluxAnchor:
            return applyFluxAnchor(target: request.target, player: request.player, board: &board)
        }
    }

    // MARK: - Polar Flip

    private static func applyPolarFlip(
        target: AbilityTarget,
        player: Player,
        board: inout Matrix5x5<Token>
    ) -> AbilityResult {
        guard case .token(let coord) = target else {
            return .failure(reason: "Invalid target for Polar Flip")
        }

        guard var token = board[coord] else {
            return .failure(reason: "No token at \(coord.notation)")
        }

        guard token.owner == player else {
            return .failure(reason: "Can only flip your own tokens")
        }

        // Flip the token
        let oldType = token.type
        token.flip()
        board[coord] = token

        return .success(description: "Flipped token at \(coord.notation) from \(oldType.rawValue) to \(token.type.rawValue)")
    }

    // MARK: - Vector Kick

    private static func applyVectorKick(
        target: AbilityTarget,
        player: Player,
        board: inout Matrix5x5<Token>
    ) -> AbilityResult {
        guard case .tokenWithDirection(let coord, let direction) = target else {
            return .failure(reason: "Invalid target for Vector Kick")
        }

        guard let token = board[coord] else {
            return .failure(reason: "No token at \(coord.notation)")
        }

        guard token.owner == player else {
            return .failure(reason: "Can only kick your own tokens")
        }

        // Build chain of tokens in direction
        var chain: [Coord] = [coord]
        var current = coord

        while let next = current.neighbor(in: direction) {
            if board[next] != nil {
                chain.append(next)
                current = next
            } else {
                break
            }
        }

        // Check if any token is locked
        for c in chain {
            if let t = board[c], t.isLocked {
                return .failure(reason: "Cannot kick locked tokens")
            }
        }

        // Push the chain (from end to start)
        var kicked: [Coord] = []
        for c in chain.reversed() {
            let dest = c.step(in: direction)

            if let tokenToPush = board[c] {
                if dest.isValid {
                    board[dest] = tokenToPush
                    board[c] = nil
                    kicked.append(c)
                } else {
                    // Token kicked off board (ejected)
                    board[c] = nil
                    kicked.append(c)
                }
            }
        }

        return .success(description: "Kicked \(kicked.count) token(s) \(direction)")
    }

    // MARK: - Flux Anchor

    private static func applyFluxAnchor(
        target: AbilityTarget,
        player: Player,
        board: inout Matrix5x5<Token>
    ) -> AbilityResult {
        guard case .token(let coord) = target else {
            return .failure(reason: "Invalid target for Flux Anchor")
        }

        guard var token = board[coord] else {
            return .failure(reason: "No token at \(coord.notation)")
        }

        guard token.owner == player else {
            return .failure(reason: "Can only anchor your own tokens")
        }

        // Set anchor flag
        token.isAnchored = true
        board[coord] = token

        return .success(description: "Anchored token at \(coord.notation)")
    }

    // MARK: - Clear Anchors

    /// Clear all anchor flags (called at start of turn)
    static func clearAnchors(board: inout Matrix5x5<Token>) {
        for coord in Matrix5x5<Token>.allCoords() {
            if var token = board[coord], token.isAnchored {
                token.isAnchored = false
                board[coord] = token
            }
        }
    }
}
