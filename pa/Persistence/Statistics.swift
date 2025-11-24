//
//  Statistics.swift
//  POLARIS ARENA
//
//  Game statistics tracking
//

import Foundation
import Combine

/// Game statistics per mode
struct GameStatistics: Codable {
    var totalGames: Int = 0
    var wins: Int = 0
    var losses: Int = 0
    var draws: Int = 0
    var totalScore: Int = 0
    var highestScore: Int = 0
    var totalTurns: Int = 0
    var tokensEjected: Int = 0

    var winRate: Double {
        guard totalGames > 0 else { return 0 }
        return Double(wins) / Double(totalGames) * 100
    }

    var averageScore: Double {
        guard totalGames > 0 else { return 0 }
        return Double(totalScore) / Double(totalGames)
    }

    var averageTurns: Double {
        guard totalGames > 0 else { return 0 }
        return Double(totalTurns) / Double(totalGames)
    }
}

/// Statistics manager
class StatisticsManager: ObservableObject {
    static let shared = StatisticsManager()

    @Published var duelStats: GameStatistics
    @Published var soloArenaStats: GameStatistics

    private let userDefaults = UserDefaults.standard
    private let duelKey = "duelStatistics"
    private let soloArenaKey = "soloArenaStatistics"

    private init() {
        // Load statistics from UserDefaults
        if let duelData = userDefaults.data(forKey: duelKey),
           let decoded = try? JSONDecoder().decode(GameStatistics.self, from: duelData) {
            self.duelStats = decoded
        } else {
            self.duelStats = GameStatistics()
        }

        if let soloData = userDefaults.data(forKey: soloArenaKey),
           let decoded = try? JSONDecoder().decode(GameStatistics.self, from: soloData) {
            self.soloArenaStats = decoded
        } else {
            self.soloArenaStats = GameStatistics()
        }
    }

    /// Record a game result
    func recordGame(
        mode: GameMode,
        didWin: Bool,
        isDraw: Bool,
        playerScore: Int,
        totalTurns: Int,
        ejections: Int
    ) {
        var stats: GameStatistics
        let key: String

        switch mode {
        case .duel:
            stats = duelStats
            key = duelKey
        case .soloArena:
            stats = soloArenaStats
            key = soloArenaKey
        case .practice, .puzzles:
            return // Don't track practice/puzzle stats
        }

        stats.totalGames += 1

        if isDraw {
            stats.draws += 1
        } else if didWin {
            stats.wins += 1
        } else {
            stats.losses += 1
        }

        stats.totalScore += playerScore
        stats.highestScore = max(stats.highestScore, playerScore)
        stats.totalTurns += totalTurns
        stats.tokensEjected += ejections

        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(stats) {
            userDefaults.set(encoded, forKey: key)
        }

        // Update published property
        DispatchQueue.main.async {
            switch mode {
            case .duel:
                self.duelStats = stats
            case .soloArena:
                self.soloArenaStats = stats
            default:
                break
            }
        }
    }

    /// Reset all statistics
    func resetAll() {
        duelStats = GameStatistics()
        soloArenaStats = GameStatistics()

        userDefaults.removeObject(forKey: duelKey)
        userDefaults.removeObject(forKey: soloArenaKey)
    }

    /// Reset statistics for specific mode
    func reset(mode: GameMode) {
        switch mode {
        case .duel:
            duelStats = GameStatistics()
            userDefaults.removeObject(forKey: duelKey)
        case .soloArena:
            soloArenaStats = GameStatistics()
            userDefaults.removeObject(forKey: soloArenaKey)
        default:
            break
        }
    }
}
