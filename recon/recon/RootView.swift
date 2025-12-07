//
//  RootView.swift
//  recon
//
//  Created by Anatoli Monsalve on 11/25/2024.
//

import SwiftUI
import Foundation

@main
struct RecOnApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("authToken") private var authToken: String = ""
    @AppStorage("needsProfileSetup") private var needsProfileSetup = false
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if authToken.isEmpty {
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
        .animation(.easeInOut, value: authToken.isEmpty)
        .animation(.easeInOut, value: needsProfileSetup)
    }
}


struct SplashView: View {
    @Binding var showSplash: Bool
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.7, blue: 0.3),
                    Color(red: 1.0, green: 0.5, blue: 0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("RecOnLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180)
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}
