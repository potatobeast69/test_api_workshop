//
//  ColorPalette.swift
//  POLARIS ARENA
//
//  Nordic Grid color scheme
//

import SwiftUI

/// App color palette
struct ColorPalette {
    // MARK: - Background
    static let backgroundDark = Color(hex: "0E1014")
    static let backgroundLight = Color(hex: "F7F7F7")

    // MARK: - Token Colors
    static let tokenA = Color(hex: "FF6B5F")  // Coral
    static let tokenB = Color(hex: "00A6A6")  // Turquoise

    // MARK: - Field Effects
    static let fieldLink = Color(hex: "FFD166")  // Amber

    // MARK: - UI Elements
    static let gridLine = Color.white.opacity(0.15)
    static let gridLineDark = Color.black.opacity(0.1)

    static let cardBackground = Color.white.opacity(0.05)
    static let cardBackgroundLight = Color.white.opacity(0.8)

    // MARK: - Text
    static let textPrimary = Color.white.opacity(0.95)
    static let textPrimaryLight = Color.black.opacity(0.9)

    static let textSecondary = Color.white.opacity(0.6)
    static let textSecondaryLight = Color.black.opacity(0.5)

    // MARK: - Semantic
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red

    // MARK: - Dynamic colors
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? backgroundDark : backgroundLight
    }

    static func text(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? textPrimary : textPrimaryLight
    }

    static func textSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? textSecondary : textSecondaryLight
    }

    static func grid(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? gridLine : gridLineDark
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
