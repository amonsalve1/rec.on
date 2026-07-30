//
//  OnboardingView.swift
//  recon
//
//  Created by Anatoli Monsalve on 11/27/2024.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage: Int = 0
    @State private var showSplash: Bool = true
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            emoji: nil,
            largeText: "Welcome to your new activity finder!",
            smallText: nil,
            bulletPoints: nil
        ),
        OnboardingPage(
            emoji: "⁉️",
            largeText: "Bored?",
            smallText: "Looking for something to do with friends? Or itching to explore your surroundings?",
            bulletPoints: nil
        ),
        OnboardingPage(
            emoji: "👋",
            largeText: "Meet your new inspiration!",
            smallText: "Swipe to decide. Remember what you like. Discover more.",
            bulletPoints: nil
        ),
        OnboardingPage(
            emoji: "🛠️",
            largeText: "How it works",
            smallText: nil,
            bulletPoints: [
                OnboardingPage.BulletPoint(icon: "arrow.right", text: "Swipe right to pick, left to discard"),
                OnboardingPage.BulletPoint(icon: "arrow.triangle.2.circlepath", text: "Randomly choose from you and your friends' picks"),
                OnboardingPage.BulletPoint(icon: "star.fill", text: "Find your next favorite thing")
            ]
        ),
        OnboardingPage(
            emoji: "😆",
            largeText: "Are you ready?",
            smallText: nil,
            bulletPoints: nil
        )
    ]

    var body: some View {
        ZStack {
            Color(red: 0.2, green: 0.2, blue: 0.2).ignoresSafeArea()

            if showSplash {
                RecOnSplashView(showSplash: $showSplash)
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Text("Intro")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.leading, 24)
                            .padding(.top, 16)
                        Spacer()
                    }

                    TabView(selection: $currentPage) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                            OnboardingPageView(page: page)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentPage)

                    VStack(spacing: 20) {
                        HStack(spacing: 8) {
                            ForEach(0..<pages.count, id: \.self) { index in
                                Circle()
                                    .frame(width: index == currentPage ? 10 : 8,
                                           height: index == currentPage ? 10 : 8)
                                    .foregroundColor(
                                        index == currentPage
                                        ? Color.white
                                        : Color.white.opacity(0.4)
                                    )
                            }
                        }
                        .padding(.bottom, 8)

                        if currentPage == pages.count - 1 {
                            Button(action: {
                                hasSeenOnboarding = true
                            }) {
                                Text("Yes!")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 1.0, green: 0.75, blue: 0.4),
                                                        Color(red: 1.0, green: 0.55, blue: 0.35)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                        } else {
                            Spacer()
                                .frame(height: 24)
                        }
                    }
                }
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
