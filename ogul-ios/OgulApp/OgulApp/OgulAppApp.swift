//
//  OgulAppApp.swift
//  OgulApp
//
//  Created by Joshua Choi on 4/16/26.
//

import SwiftUI

@main
struct OgulAppApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
