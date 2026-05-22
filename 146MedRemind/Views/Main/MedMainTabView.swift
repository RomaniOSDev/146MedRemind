//
//  MedMainTabView.swift
//  146MedRemind
//

import SwiftUI

struct MedMainTabView: View {
    @ObservedObject var viewModel: MedRemindViewModel
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: viewModel, selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "square.grid.2x2.fill")
                }
                .tag(0)

            TodayView(viewModel: viewModel)
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .tag(1)

            MedicationsView(viewModel: viewModel)
                .tabItem {
                    Label("Medications", systemImage: "pill.fill")
                }
                .tag(2)

            HistoryView(viewModel: viewModel)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(3)

            StatsView(viewModel: viewModel)
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.fill")
                }
                .tag(4)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(5)
        }
        .tint(.medPending)
        .animation(nil, value: selectedTab)
    }
}
