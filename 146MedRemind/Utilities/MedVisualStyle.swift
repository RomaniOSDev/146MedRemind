//
//  MedVisualStyle.swift
//  146MedRemind
//
//  Shared gradients, depth, and elevated surfaces for a cohesive look.
//

import SwiftUI

// MARK: - Full-screen backdrops

struct MedScreenBackdrop: View {
    enum Style {
        /// Tab roots: deep base + soft corner glows.
        case app
        /// Sheets / forms: stronger accent wash from the top.
        case sheet
        /// Medications: pending-tinted atmosphere.
        case medications
    }

    var style: Style = .app

    var body: some View {
        ZStack {
            switch style {
            case .app: appLayers
            case .sheet: sheetLayers
            case .medications: medicationsLayers
            }
        }
    }

    private var appLayers: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.09, blue: 0.14),
                    Color.medBackground,
                    Color(red: 0.035, green: 0.055, blue: 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.medPending.opacity(0.24), Color.clear],
                center: UnitPoint(x: 0.9, y: 0.05),
                startRadius: 20,
                endRadius: 320
            )

            RadialGradient(
                colors: [Color.medTaken.opacity(0.12), Color.clear],
                center: UnitPoint(x: 0.06, y: 0.4),
                startRadius: 10,
                endRadius: 240
            )

            RadialGradient(
                colors: [Color.white.opacity(0.04), Color.clear],
                center: .bottom,
                startRadius: 40,
                endRadius: 280
            )
        }
    }

    private var sheetLayers: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.medPending.opacity(0.22),
                    Color.medBackground,
                    Color(red: 0.05, green: 0.075, blue: 0.11)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.medTaken.opacity(0.16), Color.clear],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 260
            )

            RadialGradient(
                colors: [Color.black.opacity(0.35), Color.clear],
                center: .bottom,
                startRadius: 20,
                endRadius: 220
            )
        }
    }

    private var medicationsLayers: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.medPending.opacity(0.28),
                    Color.medBackground,
                    Color.medBackground.opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.medPending.opacity(0.22), Color.clear],
                center: .topTrailing,
                startRadius: 24,
                endRadius: 340
            )

            RadialGradient(
                colors: [Color.cyan.opacity(0.06), Color.clear],
                center: UnitPoint(x: 0.15, y: 0.85),
                startRadius: 30,
                endRadius: 200
            )
        }
    }
}

// MARK: - Elevated cards (glass + rim light + depth)

private struct MedElevatedCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var accent: Color = .medPending
    /// >1 slightly boosts fill contrast for hero blocks.
    var intensity: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.07 * intensity + 0.02),
                                Color.white.opacity(0.025 * intensity),
                                Color.black.opacity(0.12 * intensity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                accent.opacity(0.55),
                                accent.opacity(0.1),
                                Color.white.opacity(0.14)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.5), radius: 16, x: 0, y: 10)
            .shadow(color: accent.opacity(0.22), radius: 20, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func medElevatedCard(cornerRadius: CGFloat = 16, accent: Color = .medPending, intensity: CGFloat = 1) -> some View {
        modifier(MedElevatedCardModifier(cornerRadius: cornerRadius, accent: accent, intensity: intensity))
    }

    /// Primary action / FAB depth stack.
    func medFloatingButtonShadow(accent: Color = .medPending) -> some View {
        shadow(color: accent.opacity(0.55), radius: 18, x: 0, y: 10)
            .shadow(color: Color.black.opacity(0.45), radius: 12, x: 0, y: 8)
            .shadow(color: Color.white.opacity(0.12), radius: 1, x: 0, y: -1)
    }
}
