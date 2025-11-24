//
//  MatchLoop.swift
//  POLARIS ARENA
//
//  Main game loop and turn management
//

import Foundation
import Combine

/// Match state
enum MatchState {
    case setup
    case playing
    case finished
}

/// Turn action
enum TurnAction {
    case placement(coord: Coord, tokenType: TokenType)
    case ability(AbilityRequest)
}

/// Match result
struct MatchResult {
    let winner: Player?
    let endCondition: EndCondition
    let player1Score: Int
    let player2Score: Int
    let totalTurns: Int
}

/// Main match controller
class MatchLoop: ObservableObject {
    @Published private(set) var state: MatchState = .setup
    @Published private(set) var board: Matrix5x5<Token>
    @Published private(set) var currentPlayer: Player = .player1
    @Published private(set) var turnNumber: Int = 0

    @Published private(set) var player1Score: Int = 0
    @Published private(set) var player2Score: Int = 0

    private(set) var player1Energy: EnergyWallet
    private(set) var player2Energy: EnergyWallet

    private let rules: GameRules
    private let turnProcessor: TurnProcessor
    @Published private(set) var matchResult: MatchResult?

    init(config: GameConfig = .standard) {
        self.board = Matrix5x5<Token>()
        self.rules = GameRules(config: config)
        self.player1Energy = EnergyWallet(
            starting: config.startingEnergy,
            maximum: 20
        )
        self.player2Energy = EnergyWallet(
            starting: config.startingEnergy,
            maximum: 20
        )
        self.turnProcessor = TurnProcessor(config: config)
    }

    /// Start the match
    func start() {
        state = .playing
        turnNumber = 1
        currentPlayer = .player1
        print("🎮 Match started! Turn: \(turnNumber), Player: \(currentPlayer)")
    }

    /// Execute a turn action
    func executeTurn(action: TurnAction) -> TurnResult? {
        guard state == .playing else { return nil }

        let result: TurnResult?

        switch action {
        case .placement(let coord, let tokenType):
            result = executePlacement(coord: coord, tokenType: tokenType)

        case .ability(let request):
            result = executeAbility(request: request)
        }

        // Process result
        if let turnResult = result {
            processTurnResult(turnResult)
        }

        return result
    }

    /// Execute a placement
    private func executePlacement(coord: Coord, tokenType: TokenType) -> TurnResult? {
        guard rules.isValidPlacement(at: coord, in: board) else {
            return nil
        }

        let token = Token(owner: currentPlayer, type: tokenType)
        let result = turnProcessor.processTurn(
            placement: coord,
            token: token,
            board: board
        )

        return result
    }

    /// Execute an ability
    private func executeAbility(request: AbilityRequest) -> TurnResult? {
        // Check energy
        let energy = request.player == .player1 ? player1Energy : player2Energy

        guard energy.canAfford(request.ability.energyCost) else {
            return nil
        }

        // Apply ability
        var modifiedBoard = board
        let abilityResult = AbilityApplier.apply(request, to: &modifiedBoard)

        guard case .success = abilityResult else {
            return nil
        }

        // Spend energy
        _ = energy.spend(request.ability.energyCost)

        // Create turn result
        return TurnResult(
            finalBoard: modifiedBoard,
            cascadeResult: nil,  // Abilities don't trigger cascades
            scoreChanges: [],
            energyGain: 0
        )
    }

    /// Process turn result and update state
    private func processTurnResult(_ result: TurnResult) {
        // Update board (this will trigger SwiftUI update)
        var newBoard = result.finalBoard

        // Clear anchors BEFORE publishing
        AbilityApplier.clearAnchors(board: &newBoard)

        // Now publish the board (triggers SwiftUI update)
        board = newBoard

        // Apply score changes
        for change in result.scoreChanges {
            if change.player == .player1 {
                player1Score += change.amount
            } else {
                player2Score += change.amount
            }
        }

        // Apply energy gain
        let currentEnergy = currentPlayer == .player1 ? player1Energy : player2Energy
        currentEnergy.add(result.energyGain)

        // Check end condition
        if let endCondition = rules.checkEndCondition(turnCount: turnNumber, board: board) {
            finishMatch(endCondition: endCondition)
            return
        }

        // Next turn
        nextTurn()
    }

    /// Advance to next turn
    private func nextTurn() {
        currentPlayer = currentPlayer.opponent
        turnNumber += 1
        print("➡️ Next turn! Turn: \(turnNumber), Player: \(currentPlayer)")
    }

    /// Finish the match
    private func finishMatch(endCondition: EndCondition) {
        state = .finished

        let winner: Player?
        if let forcedWinner = endCondition.winner {
            winner = forcedWinner
        } else {
            winner = rules.determineWinner(
                player1Score: player1Score,
                player2Score: player2Score,
                board: board
            )
        }

        matchResult = MatchResult(
            winner: winner,
            endCondition: endCondition,
            player1Score: player1Score,
            player2Score: player2Score,
            totalTurns: turnNumber
        )
    }

    /// Get current player energy
    func currentPlayerEnergy() -> EnergyWallet {
        return currentPlayer == .player1 ? player1Energy : player2Energy
    }

    /// Resign current player
    func resign() {
        let endCondition = EndCondition.resignation(currentPlayer)
        finishMatch(endCondition: endCondition)
    }

    /// Reset match for new game
    func reset() {
        board = Matrix5x5<Token>()
        state = .setup
        currentPlayer = .player1
        turnNumber = 0
        player1Score = 0
        player2Score = 0
        matchResult = nil
        player1Energy = EnergyWallet(
            starting: rules.config.startingEnergy,
            maximum: 20
        )
        player2Energy = EnergyWallet(
            starting: rules.config.startingEnergy,
            maximum: 20
        )
    }
}
