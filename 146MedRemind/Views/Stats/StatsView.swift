//
//  StatsView.swift
//  146MedRemind
//

import Charts
import SwiftUI

struct StatsView: View {
    @ObservedObject var viewModel: MedRemindViewModel

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
                                    colors: [.medPending, .orange.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.medPending.opacity(0.35), radius: 12, x: 0, y: 6)
                            .padding(.horizontal)

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
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.medTaken, .medTaken.opacity(0.55)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                }
                            }
                            .frame(height: 200)
                            .padding()
                        }
                        .medElevatedCard(cornerRadius: 20, accent: .medPending, intensity: 1)
                        .padding(.horizontal)

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

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Adherence by month")
                                .font(.headline)
                                .foregroundColor(.medPending)
                                .padding(.horizontal)

                            Chart {
                                ForEach(viewModel.monthlyAdherence) { data in
                                    BarMark(
                                        x: .value("Month", data.monthLabel),
                                        y: .value("Percent", data.adherence)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.medPending, .medTaken.opacity(0.9)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                }
                            }
                            .frame(height: 200)
                            .padding()
                        }
                        .medElevatedCard(cornerRadius: 20, accent: .medPending, intensity: 1)
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("By medication")
                                .font(.headline)
                                .foregroundStyle(
                                    LinearGradient(colors: [.medPending, .medPending.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                                )
                                .padding(.horizontal, 4)

                            ForEach(viewModel.medicationStats.prefix(5)) { stat in
                                HStack {
                                    Text(stat.name)
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text("\(stat.takenCount)/\(stat.totalCount)")
                                        .foregroundStyle(
                                            LinearGradient(colors: [.medTaken, .medTaken.opacity(0.75)], startPoint: .leading, endPoint: .trailing)
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
                        .padding(14)
                        .medElevatedCard(cornerRadius: 20, accent: .medTaken, intensity: 0.95)
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
