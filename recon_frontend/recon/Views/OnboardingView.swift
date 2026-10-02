//
//  OnboardingView.swift
//  recon
//
//  Created by Anatoli Monsalve on 11/27/2024.
//

import SwiftUI

/// The first-launch intro: the brand moment, an interactive swipe tutorial,
/// and a handoff — three pages traced by a squiggle progress line.
struct OnboardingView: View {

    // MARK: - Properties

    @StateObject private var viewModel = ViewModel()

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // MARK: - Constants

    private let pageCount = 3

    // MARK: - UI

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                pager

                SquiggleProgress(
                    progress: CGFloat(viewModel.currentPage + 1) / CGFloat(pageCount),
                    tint: viewModel.currentPage == 0 ? .white : Constants.Colors.orangePrimary,
                    track: viewModel.currentPage == 0
                        ? .white.opacity(0.35)
                        : Constants.Colors.orangeLight.opacity(0.35)
                )
                .frame(width: 140, height: 12)
                .padding(.bottom, 28)
            }
        }
    }

    /// The warm brand field sits under page one and dissolves into the app
    /// background as the pages advance.
    private var background: some View {
        ZStack {
            Constants.Colors.background.ignoresSafeArea()

            LinearGradient(
                colors: [Constants.Colors.splashTop, Constants.Colors.splashBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .opacity(viewModel.currentPage == 0 ? 1 : 0)
            .animation(.easeInOut(duration: 0.35), value: viewModel.currentPage)
        }
    }

    private var pager: some View {
        TabView(selection: $viewModel.currentPage) {
            OnboardingHelloPage()
                .tag(0)

            OnboardingSwipePage {
                withAnimation {
                    viewModel.currentPage = 2
                }
            }
            .tag(1)

            OnboardingReadyPage {
                hasSeenOnboarding = true
            }
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: viewModel.currentPage)
    }

}

#Preview {
    OnboardingView()
}
