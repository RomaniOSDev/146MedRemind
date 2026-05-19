//
//  DayChip.swift
//  146MedRemind
//

import SwiftUI

struct DayChip: View {
    let day: DayOfWeek
    let isSelected: Bool

    var body: some View {
        Text(day.shortName)
            .font(.caption.weight(.bold))
            .frame(width: 34, height: 34)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.medPending, Color.medPending.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
            )
            .foregroundColor(isSelected ? Color.medBackground : Color.medPending)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.medPending.opacity(isSelected ? 0.9 : 0.45),
                                Color.medPending.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: isSelected ? Color.medPending.opacity(0.45) : Color.clear, radius: 10, x: 0, y: 5)
            .shadow(color: Color.black.opacity(isSelected ? 0.25 : 0.12), radius: 4, x: 0, y: 2)
    }
}
