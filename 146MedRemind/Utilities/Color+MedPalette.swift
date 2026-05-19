//
//  Color+MedPalette.swift
//  146MedRemind
//

import SwiftUI

extension Color {
    static let medBackground = Color(red: 0.102, green: 0.173, blue: 0.220) // #1A2C38
    static let medPending = Color(red: 0.078, green: 0.459, blue: 0.882) // #1475E1
    static let medTaken = Color(red: 0.086, green: 1.0, blue: 0.086) // #16FF16

    /// Secondary body text on dark blue UI (system Gray / .secondary are often too dim).
    static let medSecondaryLabel = Color(red: 0.72, green: 0.78, blue: 0.84)
    /// Hints, timestamps, less important lines — still WCAG-friendly on `medBackground`.
    static let medTertiaryLabel = Color(red: 0.58, green: 0.66, blue: 0.74)
}
