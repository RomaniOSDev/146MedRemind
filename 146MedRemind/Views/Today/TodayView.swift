//
//  TodayView.swift
//  146MedRemind
//

import Charts
import SwiftUI

struct TodayView: View {
    @ObservedObject var viewModel: MedRemindViewModel
    @State private var showAddMedication = false
    @State private var selectedDose: Dose?

    private var headerDateString: String {
        let f = DateFormatter()
        f.dateStyle = .full
        f.locale = Locale(identifier: "en_US")
        return f.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                MedScreenBackdrop(style: .app)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today")
                            .font(.largeTitle.bold())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.medPending, .medPending.opacity(0.75)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.medPending.opacity(0.35), radius: 12, x: 0, y: 6)

                        Text(headerDateString)
                            .foregroundColor(.medSecondaryLabel)
                            .font(.subheadline)
                    }
                    .padding(.horizontal)

                    weeklyStrip

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            StatCard(
                                title: "Scheduled today",
                                value: "\(viewModel.todayTotal)",
                                icon: "pill.fill",
                                color: .medPending
                            )
                            .frame(width: 160)

                            StatCard(
                                title: "Taken",
                                value: "\(viewModel.todayTaken)",
                                icon: "checkmark.circle.fill",
                                color: .medTaken
                            )
                            .frame(width: 140)

                            StatCard(
                                title: "Remaining",
                                value: "\(viewModel.todayPending)",
                                icon: "clock",
                                color: .medPending
                            )
                            .frame(width: 140)

                            StatCard(
                                title: "Missed",
                                value: "\(viewModel.todayMissed)",
                                icon: "exclamationmark.circle.fill",
                                color: .red
                            )
                            .frame(width: 130)

                            StatCard(
                                title: "Streak",
                                value: "\(viewModel.currentStreakDays)d",
                                icon: "flame.fill",
                                color: .orange
                            )
                            .frame(width: 120)
                        }
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Day progress")
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()

                            Text("\(viewModel.todayTaken)/\(viewModel.todayTotal)")
                                .foregroundStyle(
                                    LinearGradient(colors: [.medTaken, .medTaken.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                                )
                                .font(.headline.weight(.bold))
                        }

                        ProgressView(value: viewModel.todayProgress)
                            .tint(.medTaken)
                            .background(
                                Capsule()
                                    .fill(Color.medPending.opacity(0.28))
                                    .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
                            )
                            .frame(height: 10)
                            .scaleEffect(y: 1.8)
                    }
                    .padding(14)
                    .medElevatedCard(cornerRadius: 18, accent: .medTaken, intensity: 1.05)
                    .padding(.horizontal)

                    List {
                        ForEach(viewModel.todayDoses) { dose in
                            DoseCard(dose: dose)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedDose = dose
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    if dose.status == .pending {
                                        Button {
                                            viewModel.takeDose(dose)
                                        } label: {
                                            Label("Take", systemImage: "checkmark")
                                        }
                                        .tint(.medTaken)

                                        Button {
                                            viewModel.skipDose(dose, reason: nil)
                                        } label: {
                                            Label("Skip", systemImage: "xmark")
                                        }
                                        .tint(.red)
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

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

    private var weeklyStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 7 days")
                .font(.subheadline.weight(.semibold))
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
            .frame(height: 110)
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .medElevatedCard(cornerRadius: 18, accent: .medPending, intensity: 0.95)
            .padding(.horizontal)
        }
    }
}
