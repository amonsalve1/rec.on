//
//  OnboardingView.swift
//  recon
//
//  Created by Anatoli Monsalve on 11/27/2024.
//

import SwiftUI

/// The first-launch intro: a black splash, then a paged carousel ending in
/// the button that marks onboarding as seen.
struct OnboardingView: View {

    // MARK: - Properties

    @StateObject private var viewModel = ViewModel()

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // MARK: - UI

    var body: some View {
        ZStack {
            Constants.Colors.surfaceDark.ignoresSafeArea()

            if viewModel.showSplash {
                RecOnSplashView(showSplash: $viewModel.showSplash)
            } else {
                VStack(spacing: 0) {
                    introLabel

                    pager

                    footer
                }
            }
        }
    }

    private var introLabel: some View {
        HStack {
            Text("Intro")
                .font(Constants.Fonts.bodyMediumRounded)
                .foregroundColor(.white.opacity(0.7))
                .padding(.leading, 24)
                .padding(.top, Constants.Padding.screenHorizontal)

            Spacer()
        }
    }

    private var pager: some View {
        TabView(selection: $viewModel.currentPage) {
            ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                OnboardingPageView(page: page)
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(.easeInOut, value: viewModel.currentPage)
    }

    private var footer: some View {
        VStack(spacing: 20) {
            pageDots

            if viewModel.isOnLastPage {
                readyButton
            } else {
                Spacer()
                    .frame(height: 24)
            }
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.pages.count, id: \.self) { index in
                Circle()
                    .frame(
                        width: index == viewModel.currentPage ? 10 : 8,
                        height: index == viewModel.currentPage ? 10 : 8
                    )
                    .foregroundColor(
                        index == viewModel.currentPage
                            ? Color.white
                            : Color.white.opacity(0.4)
                    )
            }
        }
        .padding(.bottom, 8)
    }

    private var readyButton: some View {
        Button {
            hasSeenOnboarding = true
        } label: {
            Text("Yes!")
                .font(Constants.Fonts.bodySemibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Constants.Colors.orangeLight,
                                    Constants.Colors.orangePrimary
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

}

#Preview {
    OnboardingView()
}
