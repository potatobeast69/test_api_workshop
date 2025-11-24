//
//  StatisticsView.swift
//  POLARIS ARENA
//
//  Game statistics display
//

import SwiftUI

struct StatisticsView: View {
    @StateObject private var statsManager = StatisticsManager.shared
    @State private var showResetAlert = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ColorPalette.background(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        // Duel Statistics
                        StatsModeSection(
                            title: "Duel Mode",
                            subtitle: "Local PvP",
                            stats: statsManager.duelStats,
                            color: ColorPalette.tokenA
                        )

                        // Solo Arena Statistics
                        StatsModeSection(
                            title: "Solo Arena",
                            subtitle: "vs AI",
                            stats: statsManager.soloArenaStats,
                            color: ColorPalette.tokenB
                        )

                        // Reset button
                        Button(action: {
                            HapticsManager.shared.selection()
                            showResetAlert = true
                        }) {
                            Text("Reset All Statistics")
                                .font(Typography.body)
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Reset Statistics", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    statsManager.resetAll()
                    HapticsManager.shared.defeat()
                }
            } message: {
                Text("This will permanently delete all your game statistics. This action cannot be undone.")
            }
        }
    }
}

struct StatsModeSection: View {
    let title: String
    let subtitle: String
    let stats: GameStatistics
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Typography.heading)
                        .foregroundColor(ColorPalette.text(for: colorScheme))

                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundColor(ColorPalette.textSecondary(for: colorScheme))
                }

                Spacer()

                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
            }

            // Stats grid
            if stats.totalGames > 0 {
                VStack(spacing: 16) {
                    // Win/Loss/Draw
                    HStack(spacing: 16) {
                        StatCard(
                            label: "Wins",
                            value: "\(stats.wins)",
                            color: .green
                        )

                        StatCard(
                            label: "Losses",
                            value: "\(stats.losses)",
                            color: .red
                        )

                        StatCard(
                            label: "Draws",
                            value: "\(stats.draws)",
                            color: .gray
                        )
                    }

                    // Win rate
                    VStack(spacing: 8) {
                        Text("Win Rate")
                            .font(Typography.caption)
                            .foregroundColor(ColorPalette.textSecondary(for: colorScheme))

                        Text(String(format: "%.1f%%", stats.winRate))
                            .font(Typography.scoreLarge)
                            .foregroundColor(color)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )

                    // Additional stats
                    VStack(spacing: 12) {
                        StatsRow(
                            label: "Total Games",
                            value: "\(stats.totalGames)"
                        )

                        StatsRow(
                            label: "Highest Score",
                            value: "\(stats.highestScore)"
                        )

                        StatsRow(
                            label: "Average Score",
                            value: String(format: "%.1f", stats.averageScore)
                        )

                        StatsRow(
                            label: "Average Turns",
                            value: String(format: "%.1f", stats.averageTurns)
                        )

                        StatsRow(
                            label: "Tokens Ejected",
                            value: "\(stats.tokensEjected)"
                        )
                    }
                }
            } else {
                // No games played
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundColor(ColorPalette.textSecondary(for: colorScheme))

                    Text("No games played yet")
                        .font(Typography.body)
                        .foregroundColor(ColorPalette.textSecondary(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(Typography.scoreMedium)
                .foregroundColor(color)

            Text(label)
                .font(Typography.caption)
                .foregroundColor(ColorPalette.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

struct StatsRow: View {
    let label: String
    let value: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            Text(label)
                .font(Typography.body)
                .foregroundColor(ColorPalette.textSecondary(for: colorScheme))

            Spacer()

            Text(value)
                .font(Typography.scoreMedium)
                .foregroundColor(ColorPalette.text(for: colorScheme))
        }
    }
}

#Preview {
    StatisticsView()
        .preferredColorScheme(.dark)
}
