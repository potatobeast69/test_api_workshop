//
//  SoundManager.swift
//  POLARIS ARENA
//
//  Sound effects manager
//

import AVFoundation

/// Sound effect types
enum SoundEffect {
    case tokenPlace
    case attraction
    case repulsion
    case ejection
    case cascade
    case abilityActivate
    case victory
    case defeat

    var filename: String {
        switch self {
        case .tokenPlace: return "place"
        case .attraction: return "pull"
        case .repulsion: return "push"
        case .ejection: return "eject"
        case .cascade: return "cascade"
        case .abilityActivate: return "ability"
        case .victory: return "victory"
        case .defeat: return "defeat"
        }
    }
}

/// Sound manager
class SoundManager {
    static let shared = SoundManager()

    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private var isMuted: Bool = false

    private init() {
        setupAudioSession()
        // Preload sounds would happen here
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    /// Play a sound effect
    func play(_ effect: SoundEffect) {
        guard !isMuted else { return }

        // In production, load actual audio files
        // For now, this is a placeholder structure
    }

    /// Set mute state
    func setMuted(_ muted: Bool) {
        isMuted = muted
    }

    /// Toggle mute
    func toggleMute() {
        isMuted.toggle()
    }
}
