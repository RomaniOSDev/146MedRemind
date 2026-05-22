//
//  StatsView.swift
//  146MedRemind
//

import Charts
import SwiftUI

struct StatsView: View {
    @ObservedObject var viewModel: MedRemindViewModel

    private var hasAnyScheduledDoses: Bool {
        viewModel.totalDoses > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MedScreenBackdrop(style: .app)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Statistics")
                            .font(.largeTitle.bold())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.medPending, Color.orange.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.medPending.opacity(0.35), radius: 12, x: 0, y: 6)
                            .padding(.horizontal)

                        if !hasAnyScheduledDoses {
                            statsEmptyBanner
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(
                                title: "Current streak",
                                value: "\(viewModel.currentStreakDays)d",
                                icon: "flame.fill",
                                color: .orange
                            )

                            StatCard(
                                title: "Best streak",
                                value: "\(viewModel.bestStreakDays)d",
                                icon: "trophy.fill",
                                color: .medTaken
                            )
                        }
                        .padding(.horizontal)

                        weeklyChartSection

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(
                                title: "Total doses",
                                value: "\(viewModel.totalDoses)",
                                icon: "pill.fill",
                                color: .medPending
                            )

                            StatCard(
                                title: "Taken",
                                value: "\(viewModel.totalTaken)",
                                icon: "checkmark.circle.fill",
                                color: .medTaken
                            )

                            StatCard(
                                title: "Missed",
                                value: "\(viewModel.totalMissed)",
                                icon: "exclamationmark.circle.fill",
                                color: .red
                            )

                            StatCard(
                                title: "Adherence",
                                value: String(format: "%.0f%%", viewModel.adherenceRate),
                                icon: "target",
                                color: .medTaken
                            )
                        }
                        .padding(.horizontal)

                        monthlyChartSection

                        medicationBreakdownSection
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var statsEmptyBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.title2)
                .foregroundStyle(Color.medPending)
            Text("Add medications and log doses to see charts fill in.")
                .font(.subheadline)
                .foregroundStyle(Color.medSecondaryLabel)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .medElevatedCard(cornerRadius: 16, accent: .medPending, intensity: 0.9)
        .padding(.horizontal)
    }

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 7 days")
                .font(.headline)
                .foregroundColor(.medPending)
                .padding(.horizontal)

            Chart {
                ForEach(viewModel.weeklyDayStats) { day in
                    BarMark(
                        x: .value("Day", day.weekdayShort),
                        y: .value("%", day.adherencePercent)
                    )
                    .foregroundStyle(Color.medTaken)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.12))
                    AxisValueLabel {
                        if let n = value.as(Int.self) {
                            Text("\(n)%")
                                .font(.caption2)
                                .foregroundStyle(Color.medSecondaryLabel)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.caption2)
                                .foregroundStyle(Color.medSecondaryLabel)
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding()
        }
        .medElevatedCard(cornerRadius: 20, accent: .medPending, intensity: 1)
        .padding(.horizontal)
    }

    private var monthlyChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Adherence by month")
                .font(.headline)
                .foregroundColor(.medPending)
                .padding(.horizontal)

            if viewModel.monthlyAdherence.isEmpty {
                Text("No monthly data yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color.medSecondaryLabel)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                    .padding()
            } else {
                Chart {
                    ForEach(viewModel.monthlyAdherence) { data in
                        BarMark(
                            x: .value("Month", data.monthLabel),
                            y: .value("Percent", data.adherence)
                        )
                        .foregroundStyle(Color.medPending)
                    }
                }
                .chartYScale(domain: 0...100)
                .frame(height: 200)
                .padding()
            }
        }
        .medElevatedCard(cornerRadius: 20, accent: .medPending, intensity: 1)
        .padding(.horizontal)
    }

    private var medicationBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("By medication")
                .font(.headline)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.medPending, Color.medPending.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.horizontal, 4)

            if viewModel.medicationStats.isEmpty {
                Text("No medication stats yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color.medSecondaryLabel)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.medicationStats.prefix(5)) { stat in
                    HStack {
                        Text(stat.name)
                            .foregroundColor(.white)

                        Spacer()

                        Text("\(stat.takenCount)/\(stat.totalCount)")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.medTaken, Color.medTaken.opacity(0.75)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("(\(Int(stat.adherence))%)")
                            .foregroundColor(.medSecondaryLabel)
                            .font(.caption)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    )
                }
            }
        }
        .padding(14)
        .medElevatedCard(cornerRadius: 20, accent: .medTaken, intensity: 0.95)
        .padding(.horizontal)
    }
}
