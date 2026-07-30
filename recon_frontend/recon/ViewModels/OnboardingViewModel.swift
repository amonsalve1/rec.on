//
//  OnboardingViewModel.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/29/2026.
//

import Combine
import Foundation

extension OnboardingView {

    /// The ViewModel for the intro carousel shown on first launch.
    @MainActor
    class ViewModel: ObservableObject {

        // MARK: - Properties

        @Published var currentPage: Int = 0
        @Published var showSplash: Bool = true

        /// The intro carousel content, in display order.
        let pages: [OnboardingPage] = [
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
                    OnboardingPage.BulletPoint(
                        icon: "arrow.right",
                        text: "Swipe right to pick, left to discard"
                    ),
                    OnboardingPage.BulletPoint(
                        icon: "arrow.triangle.2.circlepath",
                        text: "Randomly choose from you and your friends' picks"
                    ),
                    OnboardingPage.BulletPoint(
                        icon: "star.fill",
                        text: "Find your next favorite thing"
                    )
                ]
            ),
            OnboardingPage(
                emoji: "😆",
                largeText: "Are you ready?",
                smallText: nil,
                bulletPoints: nil
            )
        ]

        // MARK: - Computed Properties

        var isOnLastPage: Bool {
            currentPage == pages.count - 1
        }

    }

}
