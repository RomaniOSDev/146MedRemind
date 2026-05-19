//
//  StatCard.swift
//  146MedRemind
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [color.opacity(0.45), color.opacity(0.08)],
                                center: .center,
                                startRadius: 4,
                                endRadius: 28
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [color.opacity(0.9), color.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )

                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.75)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .symbolRenderingMode(.hierarchical)
                }

                Spacer(minLength: 0)
            }

            Text(title)
                .foregroundStyle(Color.medSecondaryLabel)
                .font(.caption)
                .fontWeight(.medium)

            Text(value)
                .foregroundStyle(.white)
                .font(.title2)
                .fontWeight(.bold)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .medElevatedCard(cornerRadius: 18, accent: color, intensity: 1.05)
    }
}
