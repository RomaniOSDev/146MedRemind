//
//  MedMainTabView.swift
//  146MedRemind
//

import SwiftUI

/// Hosts the main `TabView`. Tab roots are created only after first visit so
/// `MedRemindViewModel` updates do not rebuild Charts and heavy stacks on every tab.
struct MedMainTabView: View {
    @ObservedObject var viewModel: MedRemindViewModel
    @Binding var selectedTab: Int

    /// Home + Settings stay in memory; other tabs load on first visit (Charts / lists are heavy).
    @State private var loadedTabs: Set<Int> = [0, 5]

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: viewModel, selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "square.grid.2x2.fill")
                }
                .tag(0)

            tabSlot(1) {
                TodayView(viewModel: viewModel)
            }
            .tabItem {
                Label("Today", systemImage: "calendar")
            }
            .tag(1)

            tabSlot(2) {
                MedicationsView(viewModel: viewModel)
            }
            .tabItem {
                Label("Medications", systemImage: "pill.fill")
            }
            .tag(2)

            tabSlot(3) {
                HistoryView(viewModel: viewModel)
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .tag(3)

            tabSlot(4) {
                StatsView(viewModel: viewModel)
            }
            .tabItem {
                Label("Statistics", systemImage: "chart.bar.fill")
            }
            .tag(4)

            tabSlot(5) {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(5)
        }
        .tint(.medPending)
        .animation(nil, value: selectedTab)
        .onChange(of: selectedTab) { newTab in
            loadedTabs.insert(newTab)
        }
        .onAppear {
            loadedTabs.insert(selectedTab)
        }
    }

    @ViewBuilder
    private func tabSlot<Content: View>(_ index: Int, @ViewBuilder content: () -> Content) -> some View {
        if loadedTabs.contains(index) {
            content()
        } else {
            Color.clear
        }
    }
}
