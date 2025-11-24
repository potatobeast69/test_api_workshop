//
//  AbilityDefinitions.swift
//  POLARIS ARENA
//
//  Tactical energy abilities
//

import Foundation

/// Available abilities
enum AbilityType: String, CaseIterable {
    case polarFlip    // Invert token polarity
    case vectorKick   // Push along axis
    case fluxAnchor   // Immune to forces next turn

    var displayName: String {
        switch self {
        case .polarFlip: return "Polar Flip"
        case .vectorKick: return "Vector Kick"
        case .fluxAnchor: return "Flux Anchor"
        }
    }

    var description: String {
        switch self {
        case .polarFlip:
            return "Flip the polarity of your token (A↔B)"
        case .vectorKick:
            return "Push a line of tokens in one direction"
        case .fluxAnchor:
            return "Token ignores forces on next turn"
        }
    }

    var energyCost: Int {
        switch self {
        case .polarFlip: return 2
        case .vectorKick: return 3
        case .fluxAnchor: return 2
        }
    }
}

/// Ability target specification
enum AbilityTarget {
    case token(Coord)                          // Single token
    case tokenWithDirection(Coord, Direction)  // Token + direction (for kick)
}

/// Ability use request
struct AbilityRequest {
    let ability: AbilityType
    let target: AbilityTarget
    let player: Player
}

/// Result of ability application
enum AbilityResult {
    case success(description: String)
    case failure(reason: String)
}
