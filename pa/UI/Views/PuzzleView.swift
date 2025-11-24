//
//  PuzzleView.swift
//  POLARIS ARENA
//
//  Puzzle mode view
//

import SwiftUI
import Combine

struct PuzzleView: View {
    @StateObject private var puzzles = PuzzleListViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            ColorPalette.background(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(puzzles.allPuzzles) { puzzle in
                        PuzzleCard(puzzle: puzzle)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Puzzles")
        .navigationBarTitleDisplayMode(.inline)
    }
}

class PuzzleListViewModel: ObservableObject {
    @Published var allPuzzles: [Puzzle] = []

    init() {
        loadPuzzles()
    }

    func loadPuzzles() {
        allPuzzles = PuzzleCatalog.shared.getAllPuzzles()
    }
}

struct PuzzleCard: View {
    let puzzle: Puzzle
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(puzzle.title)
                    .font(Typography.heading)
                    .foregroundColor(ColorPalette.text(for: colorScheme))

                Spacer()

                if puzzle.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ColorPalette.success)
                }
            }

            Text(puzzle.description)
                .font(Typography.body)
                .foregroundColor(ColorPalette.textSecondary(for: colorScheme))

            HStack {
                // Difficulty stars
                HStack(spacing: 4) {
                    ForEach(0..<5) { i in
                        Image(systemName: i < puzzle.difficulty ? "star.fill" : "star")
                            .foregroundColor(ColorPalette.fieldLink)
                            .font(.system(size: 12))
                    }
                }

                Spacer()

                Text(puzzle.objective.displayText)
                    .font(Typography.caption)
                    .foregroundColor(ColorPalette.textSecondary(for: colorScheme))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ColorPalette.grid(for: colorScheme), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        PuzzleView()
            .preferredColorScheme(.dark)
    }
}
