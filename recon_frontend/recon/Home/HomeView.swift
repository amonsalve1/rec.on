//
//  HomeView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

/// The home screen: header, solo/party entry points, friends, and recent
/// picks, with a slide-in side menu layered on top.
struct HomeView: View {

    // MARK: - Properties

    @StateObject private var viewModel = ViewModel()

    @AppStorage("userName") var userName: String = ""
    @AppStorage("userLocation") var userLocation: String = ""
    @AppStorage("userProfilePicturePath") var profilePicturePath: String = ""

    // MARK: - Constants

    private let menuWidthRatio: CGFloat = 0.7
    private let glyphSize: CGFloat = 32

    // MARK: - UI

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .trailing) {
                    content

                    menuLayer(width: geo.size.width * menuWidthRatio)
                        .zIndex(1)
                }
            }
            .fullScreenCover(isPresented: $viewModel.showProfile) {
                ProfileView(userId: nil)
            }
            .fullScreenCover(isPresented: $viewModel.showProfileFromPicks) {
                ProfileView(userId: nil)
            }
            .sheet(isPresented: $viewModel.showEditProfile) {
                editProfileSheet
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                viewModel.loadRecentPicks()
            }
        }
    }

    private var content: some View {
        ZStack(alignment: .bottom) {
            Constants.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Constants.Padding.sectionSpacing) {
                    header

                    sections
                }
            }

            glyphFooter
        }
    }

    private var header: some View {
        HomeHeaderView(
            userName: userName,
            profilePicturePath: profilePicturePath,
            onMenuTap: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    viewModel.showMenu.toggle()
                }
            }
        )
        .frame(maxWidth: .infinity)
        .padding(.horizontal, -Constants.Padding.screenHorizontal)
    }

    private var sections: some View {
        VStack(spacing: Constants.Padding.sectionSpacing) {
            HomeSoloPartySection()

            HomeFriendsSection(friends: viewModel.friends)

            HomePreviousPicksSection(recentPicks: viewModel.recentPicks) {
                viewModel.showProfileFromPicks = true
            }
        }
        .padding(.horizontal, Constants.Padding.screenHorizontal)
    }

    private var glyphFooter: some View {
        VStack {
            Spacer()

            Image("RecOnGlyph")
                .resizable()
                .scaledToFit()
                .frame(width: glyphSize, height: glyphSize)
                .padding(.bottom, 20)
        }
    }

    // MARK: - Supporting

    private func menuLayer(width: CGFloat) -> some View {
        ZStack(alignment: .trailing) {
            dimmer

            sideMenu(width: width)
        }
    }

    private var dimmer: some View {
        Color.black
            .opacity(viewModel.showMenu ? 0.65 : 0)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.25), value: viewModel.showMenu)
            .onTapGesture {
                withAnimation(Constants.Animations.menuSpring) {
                    viewModel.showMenu = false
                }
            }
            .allowsHitTesting(viewModel.showMenu)
    }

    private func sideMenu(width: CGFloat) -> some View {
        SideMenuView(
            userName: userName.isEmpty ? "User" : userName,
            profilePicturePath: profilePicturePath,
            onViewProfile: {
                withAnimation(Constants.Animations.menuSpring) {
                    viewModel.showMenu = false
                }
                viewModel.showProfile = true
            },
            onSettings: {
                withAnimation(Constants.Animations.menuSpring) {
                    viewModel.showMenu = false
                }
                viewModel.showEditProfile = true
            }
        )
        .frame(width: width)
        .offset(x: viewModel.showMenu ? 0 : width)
        .animation(
            .spring(response: 0.55, dampingFraction: 0.85)
                .delay(0.03),
            value: viewModel.showMenu
        )
    }

    private var editProfileSheet: some View {
        EditProfileView(
            currentName: userName,
            currentLocation: userLocation,
            currentProfilePicturePath: profilePicturePath,
            onSave: { name, location, picturePath in
                userName = name
                userLocation = location
                profilePicturePath = picturePath
            }
        )
    }

}

#Preview {
    HomeView()
}
