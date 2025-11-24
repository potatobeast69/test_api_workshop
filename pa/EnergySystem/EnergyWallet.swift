//
//  EnergyWallet.swift
//  POLARIS ARENA
//
//  Energy accumulation and spending
//

import Foundation

/// Player's energy wallet
class EnergyWallet {
    private(set) var current: Int
    let maximum: Int

    init(starting: Int = 0, maximum: Int = 20) {
        self.current = starting
        self.maximum = maximum
    }

    /// Add energy (capped at maximum)
    func add(_ amount: Int) {
        current = min(current + amount, maximum)
    }

    /// Spend energy if available
    func spend(_ amount: Int) -> Bool {
        guard current >= amount else { return false }
        current -= amount
        return true
    }

    /// Check if can afford
    func canAfford(_ amount: Int) -> Bool {
        return current >= amount
    }

    /// Reset to zero
    func reset() {
        current = 0
    }
}
