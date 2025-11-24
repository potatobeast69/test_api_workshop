//
//  PolarisApp.swift
//  POLARIS ARENA
//
//  Main app entry point
//

import SwiftUI

@main
struct PolarisApp: App {
    init() {
        // Setup
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            MenuView()
                .preferredColorScheme(.dark)  // Default to dark mode
        }
    }

    private func setupAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.95)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.95)
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
