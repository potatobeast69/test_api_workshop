//
//  LocalStore.swift
//  POLARIS ARENA
//
//  Local data persistence
//

import Foundation

/// Simple key-value store for app data
class LocalStore {
    static let shared = LocalStore()

    private let defaults = UserDefaults.standard

    // MARK: - Keys
    private enum Keys {
        static let gamesPlayed = "gamesPlayed"
        static let gamesWon = "gamesWon"
        static let totalMoves = "totalMoves"
        static let longestCascade = "longestCascade"
        static let puzzleProgress = "puzzleProgress"
        static let lastPlayedMode = "lastPlayedMode"
    }

    private init() {}

    // MARK: - Statistics

    var gamesPlayed: Int {
        get { defaults.integer(forKey: Keys.gamesPlayed) }
        set { defaults.set(newValue, forKey: Keys.gamesPlayed) }
    }

    var gamesWon: Int {
        get { defaults.integer(forKey: Keys.gamesWon) }
        set { defaults.set(newValue, forKey: Keys.gamesWon) }
    }

    var totalMoves: Int {
        get { defaults.integer(forKey: Keys.totalMoves) }
        set { defaults.set(newValue, forKey: Keys.totalMoves) }
    }

    var longestCascade: Int {
        get { defaults.integer(forKey: Keys.longestCascade) }
        set { defaults.set(newValue, forKey: Keys.longestCascade) }
    }

    // MARK: - Game State

    func incrementGamesPlayed() {
        gamesPlayed += 1
    }

    func incrementGamesWon() {
        gamesWon += 1
    }

    func recordMove() {
        totalMoves += 1
    }

    func recordCascade(length: Int) {
        if length > longestCascade {
            longestCascade = length
        }
    }

    // MARK: - Puzzle Progress

    func getPuzzleProgress() -> [String: Bool] {
        return defaults.dictionary(forKey: Keys.puzzleProgress) as? [String: Bool] ?? [:]
    }

    func markPuzzleCompleted(_ puzzleId: String) {
        var progress = getPuzzleProgress()
        progress[puzzleId] = true
        defaults.set(progress, forKey: Keys.puzzleProgress)
    }

    func isPuzzleCompleted(_ puzzleId: String) -> Bool {
        return getPuzzleProgress()[puzzleId] ?? false
    }

    // MARK: - Reset

    func resetStatistics() {
        gamesPlayed = 0
        gamesWon = 0
        totalMoves = 0
        longestCascade = 0
    }
}
