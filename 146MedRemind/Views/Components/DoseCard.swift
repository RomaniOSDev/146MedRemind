//
//  DoseCard.swift
//  146MedRemind
//

import SwiftUI

struct DoseCard: View {
    let dose: Dose

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .center, spacing: 4) {
                Text(formattedTime(dose.scheduledTime))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [dose.status.color, dose.status.color.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .font(.title3)
                    .fontWeight(.bold)

                if let taken = dose.takenTime {
                    Text("Taken at \(formattedTime(taken))")
                        .foregroundColor(.medSecondaryLabel)
                        .font(.caption2)
                }
            }
            .frame(width: 82)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [dose.status.color, dose.status.color.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)
                .padding(.vertical, 6)
                .shadow(color: dose.status.color.opacity(0.45), radius: 6, x: 0, y: 0)

            VStack(alignment: .leading, spacing: 6) {
                Text(dose.medicationName)
                    .foregroundColor(.white)
                    .font(.headline)

                if let line = skipReasonLine(dose) {
                    Text(line)
                        .foregroundColor(.medSecondaryLabel)
                        .font(.caption2)
                }

                HStack {
                    Text("\(dose.dosage, specifier: "%.1f") \(dose.unit.rawValue)")
                        .foregroundColor(.medSecondaryLabel)
                        .font(.caption)

                    Spacer()

                    Image(systemName: dose.status.icon)
                        .foregroundColor(dose.status.color)
                        .font(.caption.weight(.semibold))

                    Text(statusText(dose.status))
                        .foregroundColor(dose.status.color)
                        .font(.caption.weight(.semibold))
                }
            }
            .padding(.leading, 12)

            Spacer(minLength: 0)
        }
        .padding(14)
        .medElevatedCard(cornerRadius: 16, accent: dose.status.color, intensity: 1)
    }
}
