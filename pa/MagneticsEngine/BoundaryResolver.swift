//
//  BoundaryResolver.swift
//  POLARIS ARENA
//
//  Handles ejections and scoring
//

import Foundation

/// Boundary resolver for ejection scoring
struct BoundaryResolver {
    /// Convert ejection events to score changes
    static func processEjections(
        _ ejections: [EjectionEvent]
    ) -> [ScoreChange] {
        var changes: [ScoreChange] = []

        for ejection in ejections {
            // Owner loses point
            changes.append(.loseOwn(player: ejection.owner))

            // Opponent gains point
            changes.append(.ejectOpponent(by: ejection.owner.opponent))
        }

        return changes
    }

    /// Calculate energy gain from ejections
    /// +1 energy per 2 ejections
    static func energyGainFromEjections(
        _ ejections: [EjectionEvent],
        causedBy player: Player
    ) -> Int {
        let opponentEjections = ejections.filter { $0.owner != player }.count
        return opponentEjections / 2
    }
}
