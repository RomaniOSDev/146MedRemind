//
//  HistoryView.swift
//  146MedRemind
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: MedRemindViewModel
    @State private var displayedMonth = Date()
    @State private var historyFilter: HistoryDoseFilter = .all
    @State private var didPrimeSelectedDate = false

    private let weekdaySymbols = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private var monthYearString: String {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: displayedMonth)
    }

    private var calendarCells: [Date?] {
        daysInMonth()
    }

    private func daysInMonth() -> [Date?] {
        var cal = Calendar.current
        cal.firstWeekday = 2
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth)),
              let monthRange = cal.range(of: .day, in: .month, for: displayedMonth)
        else {
            return []
        }
        let weekdayOfFirst = cal.component(.weekday, from: monthStart)
        let padding = (weekdayOfFirst - cal.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: padding)
        for day in monthRange {
            if let d = cal.date(byAdding: .day, value: day - 1, to: monthStart) {
                cells.append(d)
            }
        }
        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        return cells
    }

    private var filteredDosesForSelectedDay: [Dose] {
        viewModel.dosesOnDate(viewModel.selectedDate, filter: historyFilter)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MedScreenBackdrop(style: .app)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("History")
                            .font(.largeTitle.bold())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.medPending, .medPending.opacity(0.72)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.medPending.opacity(0.35), radius: 10, x: 0, y: 5)
                            .padding(.horizontal)

                        VStack {
                            HStack {
                                Button(action: previousMonth) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.medPending)
                                }

                                Spacer()

                                Text(monthYearString)
                                    .foregroundColor(.white)
                                    .font(.headline)

                                Spacer()

                                Button(action: nextMonth) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.medPending)
                                }
                            }
                            .padding(.horizontal)

                            HStack {
                                ForEach(weekdaySymbols, id: \.self) { day in
                                    Text(day)
                                        .frame(maxWidth: .infinity)
                                        .foregroundColor(.medTertiaryLabel)
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                                ForEach(calendarCells.indices, id: \.self) { index in
                                    if let date = calendarCells[index] {
                                        DayCell(
                                            date: date,
                                            takenCount: viewModel.takenOnDate(date),
                                            totalCount: viewModel.totalOnDate(date)
                                        )
                                        .onTapGesture {
                                            viewModel.selectedDate = date
                                        }
                                        .overlay {
                                            if Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate) {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(
                                                        LinearGradient(
                                                            colors: [.medPending, .cyan.opacity(0.7)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: 2.5
                                                    )
                                                    .shadow(color: Color.medPending.opacity(0.45), radius: 6, x: 0, y: 0)
                                            }
                                        }
                                    } else {
                                        Color.clear
                                            .aspectRatio(1, contentMode: .fit)
                                    }
                                }
                            }
                            .id(monthYearString)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 10)
                        .medElevatedCard(cornerRadius: 20, accent: .medPending, intensity: 1)
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 14) {
                            Text(formattedDate(viewModel.selectedDate))
                                .font(.headline)
                                .foregroundStyle(
                                    LinearGradient(colors: [.medPending, .medPending.opacity(0.75)], startPoint: .leading, endPoint: .trailing)
                                )
                                .padding(.horizontal, 4)

                            Picker("Filter", selection: $historyFilter) {
                                ForEach(HistoryDoseFilter.allCases, id: \.self) { f in
                                    Text(f.rawValue).tag(f)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 4)

                            if filteredDosesForSelectedDay.isEmpty {
                                Text("No doses for this filter.")
                                    .font(.subheadline)
                                    .foregroundColor(.medSecondaryLabel)
                                    .padding(.horizontal, 4)
                            } else {
                                LazyVStack(spacing: 10) {
                                    ForEach(filteredDosesForSelectedDay) { dose in
                                        HistoryDoseCard(dose: dose)
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .medElevatedCard(cornerRadius: 20, accent: .medTaken, intensity: 0.95)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                guard !didPrimeSelectedDate else { return }
                didPrimeSelectedDate = true
                viewModel.selectedDate = Calendar.current.startOfDay(for: Date())
            }
        }
    }

    private func previousMonth() {
        guard let d = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) else { return }
        displayedMonth = d
    }

    private func nextMonth() {
        guard let d = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) else { return }
        displayedMonth = d
    }
}
