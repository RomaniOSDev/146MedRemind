//
//  DoseDetailSheet.swift
//  146MedRemind
//

import SwiftUI

struct DoseDetailSheet: View {
    let dose: Dose
    @ObservedObject var viewModel: MedRemindViewModel
    var onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                MedScreenBackdrop(style: .sheet)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        doseHeroCard
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: appeared)

                        if dose.status == .pending {
                            pendingActionsBlock
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 16)
                                .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.06), value: appeared)
                        } else {
                            resolvedStateBlock
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.35).delay(0.05), value: appeared)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.medBackground.opacity(0.3), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDismiss()
                    }
                    .foregroundColor(.medPending)
                }
            }
            .onAppear { appeared = true }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var doseHeroCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                dose.status.color.opacity(0.35),
                                dose.status.color.opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 90
                        )
                    )
                    .frame(width: 156, height: 156)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [dose.status.color.opacity(0.9), dose.status.color.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 5
                    )
                    .frame(width: 148, height: 148)

                VStack(spacing: 6) {
                    Text(formattedTime(dose.scheduledTime))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.7)
                    Text("Scheduled")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.medSecondaryLabel)
                        .tracking(1.2)
                }
            }

            VStack(spacing: 10) {
                Text(dose.medicationName)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)

                HStack(spacing: 10) {
                    Image(systemName: "pills.fill")
                        .foregroundColor(.medPending)
                    Text("\(dose.dosage, specifier: "%.1f") \(dose.unit.rawValue)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .overlay(Capsule().stroke(Color.medPending.opacity(0.35), lineWidth: 1))
                )

                HStack(spacing: 8) {
                    Image(systemName: dose.status.icon)
                        .symbolRenderingMode(.hierarchical)
                    Text(statusText(dose.status))
                        .font(.subheadline.weight(.bold))
                }
                .foregroundColor(dose.status.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(dose.status.color.opacity(0.15))
                )
            }
        }
        .padding(.vertical, 26)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.medPending.opacity(0.55), Color.medPending.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: Color.black.opacity(0.5), radius: 28, x: 0, y: 16)
        .shadow(color: Color.medPending.opacity(0.28), radius: 32, x: 0, y: 8)
        .shadow(color: dose.status.color.opacity(0.15), radius: 40, x: 0, y: 0)
    }

    private var pendingActionsBlock: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button {
                viewModel.takeDose(dose)
                onDismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mark as taken")
                            .font(.headline)
                        Text("Log this dose now")
                            .font(.caption)
                            .opacity(0.85)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .opacity(0.7)
                }
                .foregroundColor(Color.medBackground)
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.medTaken, Color.medTaken.opacity(0.78)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Color.medTaken.opacity(0.45), radius: 18, x: 0, y: 10)
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 12) {
                Label("Snooze reminder", systemImage: "bell.badge.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.medPending)

                HStack(spacing: 12) {
                    snoozeChip(minutes: 10, subtitle: "Coffee break")
                    snoozeChip(minutes: 30, subtitle: "Later today")
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .medElevatedCard(cornerRadius: 20, accent: .medPending, intensity: 0.95)

            Menu {
                ForEach(SkipReason.allCases, id: \.self) { reason in
                    Button {
                        viewModel.skipDose(dose, reason: reason)
                        onDismiss()
                    } label: {
                        Label(reason.rawValue, systemImage: "minus.circle")
                    }
                }
                Button(role: .destructive) {
                    viewModel.skipDose(dose, reason: nil)
                    onDismiss()
                } label: {
                    Label("Skip without reason", systemImage: "xmark.circle")
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.body.weight(.semibold))
                    Text("Skip this dose…")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.bold))
                        .opacity(0.6)
                }
                .foregroundColor(.white.opacity(0.92))
                .padding(.vertical, 16)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.red.opacity(0.22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.red.opacity(0.45), lineWidth: 1)
                        )
                )
                .shadow(color: Color.red.opacity(0.35), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.plain)
        }
    }

    private func snoozeChip(minutes: Int, subtitle: String) -> some View {
        Button {
            viewModel.snoozeReminder(medicationId: dose.medicationId, minutes: minutes)
            onDismiss()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("\(minutes)m")
                        .font(.title3.weight(.bold))
                }
                .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.medSecondaryLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.medPending.opacity(0.4), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var resolvedStateBlock: some View {
        VStack(spacing: 16) {
            if dose.status == .taken {
                if let taken = dose.takenTime {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "sparkles")
                            .font(.title)
                            .foregroundColor(.medTaken)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Logged")
                                .font(.headline)
                                .foregroundColor(.medTaken)
                            Text("Taken at \(formattedTime(taken))")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.75))
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.medTaken.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.medTaken.opacity(0.35), lineWidth: 1)
                            )
                    )
                    .shadow(color: Color.medTaken.opacity(0.25), radius: 14, x: 0, y: 6)
                }
            } else if dose.status == .missed {
                Label("This dose was missed", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.red.opacity(0.95))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.red.opacity(0.12))
                    )
                    .shadow(color: Color.red.opacity(0.3), radius: 12, x: 0, y: 6)
            } else if dose.status == .skipped {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Skipped", systemImage: "xmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.medSecondaryLabel)
                    if let line = skipReasonLine(dose) {
                        Text(line)
                            .font(.subheadline)
                            .foregroundColor(.medSecondaryLabel)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.medTertiaryLabel.opacity(0.55), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
            }
        }
    }
}
