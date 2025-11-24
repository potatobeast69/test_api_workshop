//
//  ReplayComposer.swift
//  POLARIS ARENA
//
//  Records and replays game events frame-by-frame
//

import Foundation

/// Atomic state change event
enum ReplayEvent: Codable {
    case tokenPlaced(coord: Coord, token: Token)
    case tokenMoved(from: Coord, to: Coord, tokenId: UUID)
    case tokenEjected(from: Coord, tokenId: UUID)
    case tokenFlipped(at: Coord, newType: TokenType)
    case scoreChanged(player: Player, amount: Int)
    case energyChanged(player: Player, amount: Int)
}

/// A single frame in the replay
struct ReplayFrame: Codable {
    let frameNumber: Int
    let timestamp: Double
    let events: [ReplayEvent]
    let boardSnapshot: String?  // Optional JSON snapshot

    var hasVisualChanges: Bool {
        return !events.isEmpty
    }
}

/// Complete replay recording
struct ReplayRecording: Codable {
    let matchId: UUID
    let createdAt: Date
    let frames: [ReplayFrame]
    let player1Name: String
    let player2Name: String
    let winner: Player?

    var duration: Double {
        guard let last = frames.last else { return 0 }
        return last.timestamp
    }

    var totalFrames: Int {
        return frames.count
    }
}

/// Replay composer and player
class ReplayComposer {
    private var frames: [ReplayFrame] = []
    private var currentFrame: Int = 0
    private var startTime: Date = Date()

    /// Start recording
    func startRecording() {
        frames = []
        currentFrame = 0
        startTime = Date()
    }

    /// Record events for current frame
    func recordFrame(events: [ReplayEvent]) {
        let timestamp = Date().timeIntervalSince(startTime)
        let frame = ReplayFrame(
            frameNumber: currentFrame,
            timestamp: timestamp,
            events: events,
            boardSnapshot: nil
        )

        frames.append(frame)
        currentFrame += 1
    }

    /// Record a cascade result
    func recordCascade(_ cascadeResult: CascadeResult, placement: Coord, token: Token) {
        // Initial placement
        var events: [ReplayEvent] = [
            .tokenPlaced(coord: placement, token: token)
        ]
        recordFrame(events: events)

        // Record each cascade step
        for step in cascadeResult.steps {
            var stepEvents: [ReplayEvent] = []

            // Record moves
            for move in step.moves {
                stepEvents.append(.tokenMoved(
                    from: move.from,
                    to: move.to,
                    tokenId: move.tokenId
                ))
            }

            // Record ejections
            for ejection in step.ejections {
                stepEvents.append(.tokenEjected(
                    from: ejection.from,
                    tokenId: ejection.tokenId
                ))
            }

            if !stepEvents.isEmpty {
                recordFrame(events: stepEvents)
            }
        }
    }

    /// Record score change
    func recordScoreChange(player: Player, amount: Int) {
        recordFrame(events: [.scoreChanged(player: player, amount: amount)])
    }

    /// Record energy change
    func recordEnergyChange(player: Player, amount: Int) {
        recordFrame(events: [.energyChanged(player: player, amount: amount)])
    }

    /// Finalize recording
    func finalize(player1: String, player2: String, winner: Player?) -> ReplayRecording {
        return ReplayRecording(
            matchId: UUID(),
            createdAt: Date(),
            frames: frames,
            player1Name: player1,
            player2Name: player2,
            winner: winner
        )
    }

    /// Get current recording state
    func getCurrentRecording() -> [ReplayFrame] {
        return frames
    }
}

/// Replay player for step-by-step playback
class ReplayPlayer {
    private let recording: ReplayRecording
    private var currentFrameIndex: Int = 0

    var isAtEnd: Bool {
        return currentFrameIndex >= recording.frames.count
    }

    var isAtStart: Bool {
        return currentFrameIndex == 0
    }

    var progress: Double {
        guard recording.frames.count > 0 else { return 0 }
        return Double(currentFrameIndex) / Double(recording.frames.count)
    }

    init(recording: ReplayRecording) {
        self.recording = recording
    }

    /// Get next frame
    func nextFrame() -> ReplayFrame? {
        guard !isAtEnd else { return nil }
        let frame = recording.frames[currentFrameIndex]
        currentFrameIndex += 1
        return frame
    }

    /// Get previous frame
    func previousFrame() -> ReplayFrame? {
        guard !isAtStart else { return nil }
        currentFrameIndex -= 1
        return recording.frames[currentFrameIndex]
    }

    /// Seek to specific frame
    func seek(to index: Int) {
        currentFrameIndex = max(0, min(index, recording.frames.count))
    }

    /// Reset to start
    func reset() {
        currentFrameIndex = 0
    }
}
