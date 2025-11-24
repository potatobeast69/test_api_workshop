//
//  ActionToolbar.swift
//  POLARIS ARENA
//
//  Bottom action toolbar
//

import SwiftUI

struct ActionToolbar: View {
    let onUndo: () -> Void
    let onMenu: () -> Void
    let canUndo: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 30) {
            // Undo button
            ToolbarButton(
                icon: "arrow.uturn.backward",
                label: "Undo",
                isEnabled: canUndo,
                action: onUndo
            )

            Spacer()

            // Menu button
            ToolbarButton(
                icon: "line.3.horizontal",
                label: "Menu",
                isEnabled: true,
                action: onMenu
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(ColorPalette.background(for: colorScheme))
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        )
    }
}

struct ToolbarButton: View {
    let icon: String
    let label: String
    let isEnabled: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: {
            if isEnabled {
                HapticsManager.shared.selection()
                action()
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .light))

                Text(label)
                    .font(Typography.tiny)
            }
            .foregroundColor(
                isEnabled
                    ? ColorPalette.text(for: colorScheme)
                    : ColorPalette.textSecondary(for: colorScheme)
            )
            .frame(minWidth: 60, minHeight: 44)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.4)
    }
}

#Preview {
    ZStack {
        ColorPalette.backgroundDark.ignoresSafeArea()

        VStack {
            Spacer()
            ActionToolbar(
                onUndo: {},
                onMenu: {},
                canUndo: true
            )
        }
    }
}
