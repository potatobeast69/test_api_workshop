//
//  Token.swift
//  POLARIS ARENA
//
//  Token (field nuance) model with type and state flags
//

import Foundation

/// Token polarity type
enum TokenType: String, Codable, CaseIterable {
    case A  // Repels A, attracts B
    case B  // Repels B, attracts A

    var opposite: TokenType {
        return self == .A ? .B : .A
    }

    /// Interaction with another token type
    func interacts(with other: TokenType) -> Interaction {
        return self == other ? .repulsion : .attraction
    }
}

/// Type of magnetic interaction
enum Interaction {
    case repulsion   // Same type: push away
    case attraction  // Different type: pull together
}

/// Player identifier
enum Player: String, Codable {
    case player1
    case player2

    var opponent: Player {
        return self == .player1 ? .player2 : .player1
    }
}

/// A token (field nuance) on the grid
struct Token: Codable, Identifiable {
    let id: UUID
    let owner: Player
    var type: TokenType

    // State flags
    var isAnchored: Bool     // Immune to forces (next turn only)
    var isLocked: Bool       // Permanently fixed (puzzle mode)

    init(owner: Player, type: TokenType) {
        self.id = UUID()
        self.owner = owner
        self.type = type
        self.isAnchored = false
        self.isLocked = false
    }

    /// Create with specific UUID (for replay/testing)
    init(id: UUID, owner: Player, type: TokenType, isAnchored: Bool = false, isLocked: Bool = false) {
        self.id = id
        self.owner = owner
        self.type = type
        self.isAnchored = isAnchored
        self.isLocked = isLocked
    }

    /// Check if token can be moved by forces
    var canMove: Bool {
        return !isAnchored && !isLocked
    }

    /// Flip polarity (Polar Flip ability)
    mutating func flip() {
        type = type.opposite
    }
}

extension Token: Equatable {
    static func == (lhs: Token, rhs: Token) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Token: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
