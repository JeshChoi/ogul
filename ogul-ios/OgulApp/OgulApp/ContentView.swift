//
//  ContentView.swift
//  OgulApp
//
//  Created by Joshua Choi on 4/16/26.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            ScanHistoryView()
                .tabItem {
                    Label("Scans", systemImage: "clock.fill")
                }

            AnalyticsSummaryView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .accentColor(.blue)
    }
}
