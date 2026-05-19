//
//  ContentView.swift
//  146MedRemind
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @AppStorage("medremind_onboarding_completed") private var hasCompletedOnboarding = false
    @StateObject private var viewModel = MedRemindViewModel()
    @State private var selectedTab = 0
    @State private var didBootstrap = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MedMainTabView(viewModel: viewModel, selectedTab: $selectedTab)
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .onAppear {
            guard !didBootstrap else { return }
            didBootstrap = true
            MedNotificationSetup.registerCategories()
            viewModel.loadFromUserDefaults()
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }
}

#Preview {
    ContentView()
}
