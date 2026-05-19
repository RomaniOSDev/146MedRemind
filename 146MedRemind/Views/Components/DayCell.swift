//
//  DayCell.swift
//  146MedRemind
//

import SwiftUI

struct DayCell: View {
    let date: Date
    let takenCount: Int
    let totalCount: Int

    private var calendar: Calendar { Calendar.current }

    private var fillRatio: Double {
        guard totalCount > 0 else { return 0 }
        return Double(takenCount) / Double(totalCount)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text("\(calendar.component(.day, from: date))")
                .foregroundStyle(.white)
                .font(.caption.weight(.bold))

            if totalCount > 0 {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 5)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.medTaken, .medTaken.opacity(0.65)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, CGFloat(fillRatio) * 22), height: 5)
                        .shadow(color: Color.medTaken.opacity(0.4), radius: 4, x: 0, y: 0)
                }
                .frame(width: 24)

                Text("\(takenCount)/\(totalCount)")
                    .foregroundStyle(Color.medTertiaryLabel)
                    .font(.caption2.monospacedDigit())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(totalCount > 0 ? 0.08 : 0.03),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.medPending.opacity(totalCount > 0 ? 0.35 : 0.12),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(totalCount > 0 ? 0.35 : 0.15), radius: 8, x: 0, y: 4)
    }
}
