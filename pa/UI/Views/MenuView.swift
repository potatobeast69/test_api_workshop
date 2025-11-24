//
//  MenuView.swift
//  POLARIS ARENA
//
//  Main menu
//

import SwiftUI

enum GameMode: Hashable {
    case duel
    case soloArena
    case practice
    case puzzles
}

struct MenuView: View {
    @State private var selectedMode: GameMode?
    @State private var showSettings = false
    @State private var showStatistics = false
    @State private var showOnboarding = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                ColorPalette.background(for: colorScheme)
                    .ignoresSafeArea()

                // Subtle field lines background
                FieldLinesBackground()
                    .opacity(0.05)

                VStack(spacing: 40) {
                    Spacer()

                    // Title (minimal)
                    VStack(spacing: 8) {
                        Text("POLARIS")
                            .font(Typography.title)
                            .foregroundColor(ColorPalette.text(for: colorScheme))
                            .tracking(4)

                        Text("ARENA")
                            .font(Typography.caption)
                            .foregroundColor(ColorPalette.textSecondary(for: colorScheme))
                            .tracking(6)
                    }

                    Spacer()

                    // Menu options
                    VStack(spacing: 16) {
                        NavigationLink(value: GameMode.duel) {
                            MenuButtonContent(
                                title: "Duel",
                                subtitle: "Local PvP",
                                icon: "person.2.fill"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .simultaneousGesture(TapGesture().onEnded {
                            HapticsManager.shared.selection()
                        })

                        NavigationLink(value: GameMode.soloArena) {
                            MenuButtonContent(
                                title: "Solo Arena",
                                subtitle: "vs AI",
                                icon: "cpu"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .simultaneousGesture(TapGesture().onEnded {
                            HapticsManager.shared.selection()
                        })
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    // Bottom buttons
                    HStack(spacing: 40) {
                        Button(action: {
                            HapticsManager.shared.selection()
                            showStatistics = true
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 20))
                                Text("Statistics")
                                    .font(Typography.tiny)
                            }
                            .foregroundColor(ColorPalette.textSecondary(for: colorScheme))
                        }

                        Button(action: {
                            HapticsManager.shared.selection()
                            showSettings = true
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                Text("Settings")
                                    .font(Typography.tiny)
                            }
                            .foregroundColor(ColorPalette.textSecondary(for: colorScheme))
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationDestination(for: GameMode.self) { mode in
                GameView(gameMode: mode)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showStatistics) {
                StatisticsView()
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(onComplete: {
                    hasSeenOnboarding = true
                    showOnboarding = false
                })
            }
            .onAppear {
                if !hasSeenOnboarding {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showOnboarding = true
                    }
                }
            }
        }
    }
}

struct MenuButtonContent: View {
    let title: String
    let subtitle: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(ColorPalette.fieldLink)
                .frame(width: 40)

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Typography.heading)
                    .foregroundColor(ColorPalette.text(for: colorScheme))

                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundColor(ColorPalette.textSecondary(for: colorScheme))
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(ColorPalette.textSecondary(for: colorScheme))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
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

/// Decorative background
struct FieldLinesBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let spacing: CGFloat = 60

                // Horizontal lines
                for i in stride(from: 0, to: geometry.size.height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: i))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: i))
                }

                // Vertical lines
                for i in stride(from: 0, to: geometry.size.width, by: spacing) {
                    path.move(to: CGPoint(x: i, y: 0))
                    path.addLine(to: CGPoint(x: i, y: geometry.size.height))
                }
            }
            .stroke(Color.white, lineWidth: 0.5)
        }
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    @Environment(\.colorScheme) var colorScheme

    private let pages: [(title: String, description: String, icon: String)] = [
        (
            title: "Welcome to Polaris Arena",
            description: "A strategic grid-based game where magnetic forces create dynamic gameplay",
            icon: "sparkles"
        ),
        (
            title: "Place Your Tokens",
            description: "Choose between Type A and Type B tokens. Each type has unique magnetic properties",
            icon: "circle.grid.3x3.fill"
        ),
        (
            title: "Magnetic Forces",
            description: "Same types repel, opposite types attract. Use physics to control the board!",
            icon: "bolt.fill"
        ),
        (
            title: "Score Points",
            description: "Eject opponent tokens off the board and maintain strong positions to win",
            icon: "trophy.fill"
        )
    ]

    var body: some View {
        ZStack {
            ColorPalette.background(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? ColorPalette.fieldLink : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)

                Spacer()

                // Content
                VStack(spacing: 30) {
                    Image(systemName: pages[currentPage].icon)
                        .font(.system(size: 80))
                        .foregroundColor(ColorPalette.fieldLink)

                    VStack(spacing: 16) {
                        Text(pages[currentPage].title)
                            .font(Typography.heading)
                            .foregroundColor(ColorPalette.text(for: colorScheme))
                            .multilineTextAlignment(.center)

                        Text(pages[currentPage].description)
                            .font(Typography.body)
                            .foregroundColor(ColorPalette.textSecondary(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }

                Spacer()

                // Navigation buttons
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            Text("Back")
                                .font(Typography.body)
                                .foregroundColor(ColorPalette.textSecondary(for: colorScheme))
                                .padding(.horizontal, 30)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }

                    Spacer()

                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            onComplete()
                        }
                    }) {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(Typography.body)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 16)
                            .background(ColorPalette.fieldLink)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    MenuView()
        .preferredColorScheme(.dark)
}
