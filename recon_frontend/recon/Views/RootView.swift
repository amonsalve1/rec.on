//
//  RootView.swift
//  recon
//
//  Created by Anatoli Monsalve on 11/25/2024.
//

import SwiftUI

/// The root switcher that routes between sign-in, profile setup, onboarding,
/// and the home screen based on persisted session state.
struct RootView: View {

    // MARK: - Properties

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasSession") private var hasSession = false
    @AppStorage("needsProfileSetup") private var needsProfileSetup = false

    @State private var showSplash = true

    // MARK: - UI

    var body: some View {
        ZStack {
            if !hasSession {
                SignInView()
            } else if needsProfileSetup {
                ProfileSetupView()
            } else if hasSeenOnboarding {
                HomeView()
            } else if showSplash {
                SplashView(showSplash: $showSplash)
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut, value: showSplash)
        .animation(.easeInOut, value: hasSession)
        .animation(.easeInOut, value: needsProfileSetup)
    }

}

#Preview {
    RootView()
}
