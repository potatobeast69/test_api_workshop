//
//  HapticsManager.swift
//  POLARIS ARENA
//
//  Haptic feedback system
//

import UIKit
import CoreHaptics

/// Haptic feedback manager
class HapticsManager {
    static let shared = HapticsManager()

    private var engine: CHHapticEngine?
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        setupHapticsEngine()
    }

    private func setupHapticsEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return
        }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptics engine error: \(error)")
        }
    }

    // MARK: - Game Events

    /// Token placement (soft click)
    func tokenPlaced() {
        impactLight.impactOccurred(intensity: 0.6)
    }

    /// Attraction force (soft pull)
    func attraction() {
        guard let engine = engine else {
            impactLight.impactOccurred(intensity: 0.5)
            return
        }

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)

        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensity, sharpness],
            relativeTime: 0,
            duration: 0.15
        )

        playPattern([event])
    }

    /// Repulsion force (sharp push)
    func repulsion() {
        impactMedium.impactOccurred(intensity: 0.8)
    }

    /// Token ejected (strong impact)
    func ejection() {
        impactHeavy.impactOccurred(intensity: 1.0)
    }

    /// Cascade chain (rhythmic pulses)
    func cascade(length: Int) {
        guard let engine = engine else {
            impactMedium.impactOccurred()
            return
        }

        var events: [CHHapticEvent] = []

        for i in 0..<min(length, 5) {
            let intensity = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: Float(0.6 - (Double(i) * 0.1))
            )
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: 0.5
            )

            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: Double(i) * 0.12
            )

            events.append(event)
        }

        playPattern(events)
    }

    /// Energy ability activated
    func abilityActivated() {
        guard let engine = engine else {
            impactMedium.impactOccurred()
            return
        }

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensity, sharpness],
            relativeTime: 0
        )

        playPattern([event])
    }

    /// Victory (long pleasant tone)
    func victory() {
        guard let engine = engine else {
            impactHeavy.impactOccurred()
            return
        }

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)

        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensity, sharpness],
            relativeTime: 0,
            duration: 0.5
        )

        playPattern([event])
    }

    /// Defeat (descending tone)
    func defeat() {
        impactMedium.impactOccurred()
    }

    /// UI selection
    func selection() {
        selectionGenerator.selectionChanged()
    }

    // MARK: - Pattern Playback

    private func playPattern(_ events: [CHHapticEvent]) {
        guard let engine = engine else { return }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic pattern error: \(error)")
        }
    }
}
