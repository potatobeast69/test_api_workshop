//
//  TurnProcessor.swift
//  POLARIS ARENA
//
//  Processes a complete turn: placement → simulation → scoring
//

import Foundation

/// Result of processing a turn
struct TurnResult {
    let finalBoard: Matrix5x5<Token>
    let cascadeResult: CascadeResult?
    let scoreChanges: [ScoreChange]
    let energyGain: Int
}

/// Turn processor
class TurnProcessor {
    private let config: GameConfig
    private let cascadeManager: CascadeManager
    private let rules: GameRules

    init(config: GameConfig) {
        self.config = config
        self.cascadeManager = CascadeManager()
        self.rules = GameRules(config: config)
    }

    /// Process a complete turn
    func processTurn(
        placement: Coord,
        token: Token,
        board: Matrix5x5<Token>
    ) -> TurnResult {
        // 1. Simulate cascade
        let cascadeResult = cascadeManager.simulate(
            placement: placement,
            token: token,
            initialBoard: board
        )

        // 2. Calculate score changes
        let scoreChanges = BoundaryResolver.processEjections(
            cascadeResult.totalEjections
        )

        // 3. Calculate energy gain
        var energyGain = config.energyPerTurn

        // Bonus energy from ejections
        let ejectionBonus = BoundaryResolver.energyGainFromEjections(
            cascadeResult.totalEjections,
            causedBy: token.owner
        )
        energyGain += ejectionBonus

        // 4. Return result
        return TurnResult(
            finalBoard: cascadeResult.finalBoard,
            cascadeResult: cascadeResult,
            scoreChanges: scoreChanges,
            energyGain: energyGain
        )
    }
}
