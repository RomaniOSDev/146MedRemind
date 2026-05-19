//
//  HomeView.swift
//  146MedRemind
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: MedRemindViewModel
    @Binding var selectedTab: Int

    @State private var showAddMedication = false
    @State private var selectedDose: Dose?

    private let gridSpacing: CGFloat = 12
    private var gridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: gridSpacing), GridItem(.flexible(), spacing: gridSpacing)]
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                homeBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        headerRow

                        LazyVGrid(columns: gridColumns, spacing: gridSpacing) {
                            todayRingTile
                            streakTile
                            nextDoseTile
                            weekDotsTile
                            if viewModel.lowStockMedicationsCount > 0 {
                                lowStockTile
                            }
                        }

                        quickJumpRow

                        if !viewModel.todayDoses.isEmpty {
                            doseStripSection
                        } else {
                            emptyTodayHint
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                    .padding(.top, 8)
                }

                addButton
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAddMedication) {
                AddMedicationView(viewModel: viewModel)
            }
            .sheet(item: $selectedDose) { dose in
                DoseDetailSheet(dose: dose, viewModel: viewModel) {
                    selectedDose = nil
                }
            }
        }
    }

    private var homeBackground: some View {
        MedScreenBackdrop(style: .app)
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 52, height: 52)
                Image(systemName: "heart.text.square.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.pink, .white.opacity(0.9))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(Date(), format: .dateTime.month(.abbreviated).day())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.medSecondaryLabel)
                Text(Date(), format: .dateTime.weekday(.wide))
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
            }
            .foregroundColor(.white)
            .environment(\.locale, Locale(identifier: "en_US"))

            Spacer(minLength: 0)

            Image(systemName: "bell.and.waves.left.and.right.fill")
                .font(.title3)
                .foregroundStyle(Color.medPending.opacity(0.85))
                .accessibilityLabel("Reminders")
        }
    }

    private var todayRingTile: some View {
        Button {
            selectedTab = 1
        } label: {
            widgetShell(accent: .medTaken) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 9)
                        .frame(width: 88, height: 88)

                    Circle()
                        .trim(from: 0, to: viewModel.todayTotal > 0 ? viewModel.todayProgress : 0)
                        .stroke(
                            AngularGradient(
                                colors: [.medTaken, .medPending, .medTaken],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                        )
                        .frame(width: 88, height: 88)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Image(systemName: "sun.max.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.yellow, .orange)
                        if viewModel.todayTotal > 0 {
                            Text("\(viewModel.todayTaken)/\(viewModel.todayTotal)")
                                .font(.caption.bold().monospacedDigit())
                                .foregroundColor(.white.opacity(0.9))
                        } else {
                            Image(systemName: "moon.zzz.fill")
                                .font(.caption)
                                .foregroundStyle(Color.medSecondaryLabel)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                Label("Today", systemImage: "calendar")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.medSecondaryLabel)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens Today tab")
    }

    private var streakTile: some View {
        Button {
            selectedTab = 4
        } label: {
            widgetShell(accent: .orange) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 44))
                    .symbolRenderingMode(.multicolor)
                    .padding(.vertical, 6)

                HStack(spacing: 6) {
                    Text("\(viewModel.currentStreakDays)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundStyle(.orange.opacity(0.9))
                }

                Label("Streak", systemImage: "flame")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.medSecondaryLabel)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens Statistics")
    }

    private var nextDoseTile: some View {
        Button {
            if let d = viewModel.nextUpcomingDose {
                selectedDose = d
            } else {
                selectedTab = 1
            }
        } label: {
            widgetShell(accent: .medPending) {
                if let dose = viewModel.nextUpcomingDose {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.medPending, .cyan.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.vertical, 4)

                    Text(formattedTime(dose.scheduledTime))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.white.opacity(0.58))
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.medTaken)
                        .symbolRenderingMode(.hierarchical)
                        .padding(.vertical, 8)
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.yellow.opacity(0.9))
                }

                Label("Next", systemImage: "clock")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.medSecondaryLabel)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.nextUpcomingDose.map { "Next dose at \(formattedTime($0.scheduledTime))" } ?? "No upcoming dose")
    }

    private var weekDotsTile: some View {
        Button {
            selectedTab = 1
        } label: {
            widgetShell(accent: .medTaken) {
                HStack(spacing: 8) {
                    ForEach(viewModel.weeklyDayStats) { day in
                        VStack(spacing: 6) {
                            Capsule()
                                .fill(dotColor(for: day))
                                .frame(width: 10, height: min(36, CGFloat(day.adherencePercent) * 0.32 + 8))
                            Text(String(day.weekdayShort.prefix(1)))
                                .font(.caption2.bold())
                                .foregroundStyle(Color.medSecondaryLabel)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 6)

                Label("Week", systemImage: "chart.bar.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.medSecondaryLabel)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens Today")
    }

    private func dotColor(for day: MedRemindViewModel.WeeklyDayStat) -> Color {
        if day.scheduled == 0 { return Color.white.opacity(0.12) }
        if day.adherencePercent >= 100 { return .medTaken }
        if day.adherencePercent >= 50 { return .medPending }
        return .red.opacity(0.75)
    }

    private var lowStockTile: some View {
        Button {
            selectedTab = 2
        } label: {
            widgetShell(accent: .yellow) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.yellow, .orange)
                    .symbolRenderingMode(.palette)
                    .padding(.vertical, 8)

                Text("\(viewModel.lowStockMedicationsCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Label("Low stock", systemImage: "shippingbox")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.medSecondaryLabel)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens Medications")
    }

    private var quickJumpRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                jumpChip(tab: 1, systemImage: "calendar", tint: .medPending)
                jumpChip(tab: 2, systemImage: "pill.fill", tint: .cyan)
                jumpChip(tab: 3, systemImage: "clock.arrow.circlepath", tint: .purple.opacity(0.9))
                jumpChip(tab: 4, systemImage: "chart.bar.fill", tint: .orange)
                jumpChip(tab: 5, systemImage: "gearshape.fill", tint: Color.medSecondaryLabel)
            }
            .padding(.vertical, 2)
        }
    }

    private func jumpChip(tab: Int, systemImage: String, tint: Color) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Image(systemName: systemImage)
                .font(.title2)
                .frame(width: 56)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(tint.opacity(0.45), lineWidth: 1)
                        )
                )
                .foregroundStyle(tint)
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
                .shadow(color: tint.opacity(0.28), radius: 14, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var doseStripSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "list.bullet.rectangle.fill")
                    .foregroundStyle(Color.medPending)
                Text("Today")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.92))
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.todayDoses) { dose in
                        doseChip(dose)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func doseChip(_ dose: Dose) -> some View {
        Button {
            selectedDose = dose
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(dose.status.color.opacity(0.22))
                        .frame(width: 44, height: 44)
                    Image(systemName: dose.status.icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(dose.status.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedTime(dose.scheduledTime))
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(.white)
                    Text(dose.medicationName)
                        .font(.caption2)
                        .foregroundStyle(Color.medSecondaryLabel)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .medElevatedCard(cornerRadius: 16, accent: dose.status.color, intensity: 0.9)
        .buttonStyle(.plain)
    }

    private var emptyTodayHint: some View {
        HStack(spacing: 14) {
            Image(systemName: "tray.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.medPending.opacity(0.6))
            VStack(alignment: .leading, spacing: 4) {
                Text("Nothing scheduled")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Text("Add a medication")
                    .font(.caption)
                    .foregroundStyle(Color.medSecondaryLabel)
            }
            Spacer(minLength: 0)
            Image(systemName: "plus.circle.fill")
                .font(.title)
                .foregroundStyle(Color.medTaken)
        }
        .padding(16)
        .medElevatedCard(cornerRadius: 18, accent: .medPending, intensity: 0.9)
    }

    private var addButton: some View {
        Button {
            showAddMedication = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, Color.medPending)
                .font(.system(size: 56))
                .medFloatingButtonShadow(accent: .medPending)
        }
        .padding(24)
        .accessibilityLabel("Add medication")
    }

    @ViewBuilder
    private func widgetShell(accent: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 8) {
            content()
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .medElevatedCard(cornerRadius: 22, accent: accent, intensity: 1.02)
    }
}

#Preview {
    ContentView()
}
