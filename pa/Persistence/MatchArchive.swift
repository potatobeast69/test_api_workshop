//
//  MatchArchive.swift
//  POLARIS ARENA
//
//  Save and load match replays
//

import Foundation

/// Match archive manager
class MatchArchive {
    static let shared = MatchArchive()

    private var archiveURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Replays")
    }

    private init() {
        createArchiveDirectory()
    }

    private func createArchiveDirectory() {
        try? FileManager.default.createDirectory(
            at: archiveURL,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Save

    func save(_ recording: ReplayRecording) -> Bool {
        let filename = "\(recording.matchId.uuidString).replay"
        let fileURL = archiveURL.appendingPathComponent(filename)

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(recording)
            try data.write(to: fileURL)
            return true
        } catch {
            print("Failed to save replay: \(error)")
            return false
        }
    }

    // MARK: - Load

    func load(matchId: UUID) -> ReplayRecording? {
        let filename = "\(matchId.uuidString).replay"
        let fileURL = archiveURL.appendingPathComponent(filename)

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ReplayRecording.self, from: data)
        } catch {
            print("Failed to load replay: \(error)")
            return nil
        }
    }

    // MARK: - List

    func listReplays() -> [ReplayRecording] {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: archiveURL,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )

            let replays = files
                .filter { $0.pathExtension == "replay" }
                .compactMap { url -> ReplayRecording? in
                    guard let data = try? Data(contentsOf: url) else { return nil }
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    return try? decoder.decode(ReplayRecording.self, from: data)
                }
                .sorted { $0.createdAt > $1.createdAt }

            return replays
        } catch {
            print("Failed to list replays: \(error)")
            return []
        }
    }

    // MARK: - Delete

    func delete(matchId: UUID) -> Bool {
        let filename = "\(matchId.uuidString).replay"
        let fileURL = archiveURL.appendingPathComponent(filename)

        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            print("Failed to delete replay: \(error)")
            return false
        }
    }

    func deleteAll() {
        let replays = listReplays()
        for replay in replays {
            _ = delete(matchId: replay.matchId)
        }
    }
}
