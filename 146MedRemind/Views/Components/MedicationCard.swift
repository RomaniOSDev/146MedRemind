//
//  MedicationCard.swift
//  146MedRemind
//

import SwiftUI

struct MedicationCard: View {
    let medication: Medication
    let takenTodayCount: Int
    let nextDoseDate: Date?

    private var isActive: Bool { medication.isActive }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isActive
                            ? [Color.medPending, Color.medPending.opacity(0.45)]
                            : [Color.medTertiaryLabel.opacity(0.55), Color.medTertiaryLabel.opacity(0.22)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.medPending.opacity(isActive ? 0.35 : 0.12),
                                        Color.medPending.opacity(isActive ? 0.12 : 0.06)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)

                        Image(systemName: isActive ? "pills.fill" : "pills")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(
                                isActive
                                    ? LinearGradient(colors: [.medTaken, .medPending], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(
                                        colors: [Color.medTertiaryLabel, Color.medTertiaryLabel.opacity(0.75)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(medication.name)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)

                        Text("\(medication.dosage, specifier: "%.1f") \(medication.unit.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.medSecondaryLabel)
                    }

                    Spacer(minLength: 8)

                    if takenTodayCount > 0 {
                        VStack(spacing: 2) {
                            Text("\(takenTodayCount)")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.medTaken)
                            Text("today")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.medTaken.opacity(0.85))
                                .textCase(.uppercase)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.medTaken.opacity(0.14))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.medTaken.opacity(0.45), lineWidth: 1)
                                )
                        )
                    }
                }

                if let instructions = medication.instructions, !instructions.isEmpty {
                    Text(instructions)
                        .font(.caption)
                        .foregroundColor(.medPending.opacity(0.95))
                        .lineLimit(2)
                }

                if let stock = medication.stockCount {
                    HStack(spacing: 8) {
                        Image(systemName: "shippingbox.fill")
                            .font(.caption)
                            .foregroundColor(.medPending)
                        Text("On hand: \(stock)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white.opacity(0.85))
                        if stock <= medication.lowStockThreshold {
                            Text("Low")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.red.opacity(0.2)))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    if let nextDose = nextDoseDate {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.medPending)
                            Text("Next dose")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white.opacity(0.65))
                            Spacer(minLength: 0)
                            Text(formattedTime(nextDose))
                                .font(.caption.weight(.bold).monospacedDigit())
                                .foregroundColor(.medPending)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.medPending.opacity(0.12))
                        )
                    }

                    if let refillDate = medication.refillDate {
                        HStack(spacing: 8) {
                            Image(systemName: refillDate < Date() ? "exclamationmark.triangle.fill" : "calendar")
                                .font(.caption)
                                .foregroundColor(refillDate < Date() ? .red : .medTertiaryLabel)
                            Text(refillDate < Date() ? "Out of stock" : "Refill by")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.medSecondaryLabel)
                            Spacer(minLength: 0)
                            Text(refillDate < Date() ? "—" : formattedShortDate(refillDate))
                                .font(.caption.weight(.semibold).monospacedDigit())
                                .foregroundColor(refillDate < Date() ? .red : .medSecondaryLabel)
                        }
                    }
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 14)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.07),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.medPending.opacity(isActive ? 0.55 : 0.2),
                            Color.medPending.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.45), radius: 18, x: 0, y: 10)
        .shadow(color: Color.medPending.opacity(isActive ? 0.2 : 0), radius: 24, x: 0, y: 6)
        .shadow(color: Color.white.opacity(0.04), radius: 1, x: 0, y: -1)
        .opacity(medication.isArchived ? 0.65 : 1)
        .overlay(alignment: .topTrailing) {
            if medication.isArchived {
                Text("Archived")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.medBackground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.gray.opacity(0.85)))
                    .padding(10)
            }
        }
    }
}
