//
//  EnergyBar.swift
//  POLARIS ARENA
//
//  Energy display and ability buttons
//

import SwiftUI

struct EnergyBar: View {
    let currentEnergy: Int
    let maxEnergy: Int
    let player: Player
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            // Energy amount
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12))
                    .foregroundColor(ColorPalette.fieldLink)

                Text("\(currentEnergy)")
                    .font(Typography.scoreSmall)
                    .foregroundColor(ColorPalette.text(for: colorScheme))

                Text("/ \(maxEnergy)")
                    .font(Typography.caption)
                    .foregroundColor(ColorPalette.textSecondary(for: colorScheme))
            }

            // Energy bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))

                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ColorPalette.fieldLink)
                        .frame(
                            width: geometry.size.width * CGFloat(currentEnergy) / CGFloat(maxEnergy)
                        )
                        .animation(.easeOut(duration: Typography.animationNormal), value: currentEnergy)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
}

#Preview {
    ZStack {
        ColorPalette.backgroundDark.ignoresSafeArea()
        VStack(spacing: 20) {
            EnergyBar(currentEnergy: 5, maxEnergy: 20, player: .player1)
            EnergyBar(currentEnergy: 12, maxEnergy: 20, player: .player2)
            EnergyBar(currentEnergy: 20, maxEnergy: 20, player: .player1)
        }
        .padding()
    }
}
