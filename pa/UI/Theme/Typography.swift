//
//  Typography.swift
//  POLARIS ARENA
//
//  Typography system
//

import SwiftUI

/// Typography styles
struct Typography {
    // MARK: - Fonts
    static let title = Font.system(size: 32, weight: .light, design: .rounded)
    static let heading = Font.system(size: 24, weight: .medium, design: .rounded)
    static let subheading = Font.system(size: 18, weight: .regular, design: .rounded)
    static let body = Font.system(size: 16, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 14, weight: .light, design: .rounded)
    static let tiny = Font.system(size: 12, weight: .light, design: .rounded)

    // MARK: - Monospaced (for scores, stats)
    static let scoreLarge = Font.system(size: 36, weight: .semibold, design: .monospaced)
    static let scoreMedium = Font.system(size: 24, weight: .medium, design: .monospaced)
    static let scoreSmall = Font.system(size: 16, weight: .regular, design: .monospaced)

    // MARK: - Animation timings
    static let animationFast: Double = 0.15
    static let animationNormal: Double = 0.25
    static let animationSlow: Double = 0.35
}
