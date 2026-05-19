//
//  HistoryDoseCard.swift
//  146MedRemind
//

import SwiftUI

struct HistoryDoseCard: View {
    let dose: Dose

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(dose.status.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: dose.status.icon)
                    .foregroundStyle(dose.status.color)
                    .font(.body.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(dose.medicationName)
                    .foregroundColor(.white)
                    .font(.headline)
                Text("\(dose.dosage, specifier: "%.1f") \(dose.unit.rawValue)")
                    .foregroundColor(.medSecondaryLabel)
                    .font(.caption)
                if let line = skipReasonLine(dose) {
                    Text(line)
                        .foregroundColor(.medSecondaryLabel)
                        .font(.caption2)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedTime(dose.scheduledTime))
                    .foregroundColor(.medSecondaryLabel)
                    .font(.caption.weight(.semibold))
                if let taken = dose.takenTime {
                    Text("✓ \(formattedTime(taken))")
                        .foregroundColor(.medTaken)
                        .font(.caption.weight(.medium))
                }
            }
        }
        .padding(14)
        .medElevatedCard(cornerRadius: 16, accent: dose.status.color, intensity: 0.95)
    }
}
