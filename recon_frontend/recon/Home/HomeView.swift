//
//  HomeView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

/// The home screen: start a decision in one tap, see the ones already
/// running, and glance at what was decided lately.
struct HomeView: View {

    // MARK: - Properties

    @StateObject private var viewModel = ViewModel()

    @AppStorage("userName") var userName: String = ""
    @AppStorage("userLocation") var userLocation: String = ""
    @AppStorage("userProfilePicturePath") var profilePicturePath: String = ""

    @State private var soloTopic: String?
    @State private var partyTopic: String?
    @State private var resumingParty: PartySummaryDTO?
    @State private var showJoin = false

    // MARK: - Constants

    private let menuWidthRatio: CGFloat = 0.7

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
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $viewModel.showProfile) {
                ProfileView(userId: nil)
            }
            .fullScreenCover(isPresented: $viewModel.showProfileFromPicks) {
                ProfileView(userId: nil)
            }
            .sheet(isPresented: $viewModel.showEditProfile) {
                editProfileSheet
            }
            .sheet(isPresented: $showJoin) {
                HomeJoinSheet { code, done in
                    viewModel.join(code: code, completion: done)
                }
                .presentationDetents([.height(340)])
            }
            .sheet(item: $viewModel.pendingTopic) { topic in
                HomeStartSheet(
                    topic: topic,
                    onSolo: {
                        viewModel.pendingTopic = nil
                        soloTopic = topic.id
                    },
                    onParty: {
                        viewModel.pendingTopic = nil
                        partyTopic = topic.id
                    }
                )
                .presentationDetents([.height(280)])
            }
            .navigationDestination(item: $soloTopic) { topic in
                SoloFlowView(presetTopic: topic)
            }
            .navigationDestination(item: $partyTopic) { topic in
                PartySetupView(presetTopic: topic)
            }
            .navigationDestination(item: $resumingParty) { party in
                PartyResumeView(summary: party)
            }
            .task {
                viewModel.refresh()
            }
        }
    }

    private var content: some View {
        ZStack {
            CanvasBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    HomeHeaderView(
                        userName: userName,
                        profilePicturePath: profilePicturePath,
                        onMenuTap: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                viewModel.showMenu.toggle()
                            }
                        },
                        onJoinTap: {
                            showJoin = true
                        }
                    )
                    .padding(.horizontal, 24)

                    HomeTopicsSection(
                        topics: viewModel.topics,
                        nearby: viewModel.nearbyPreview,
                        nearbyCount: viewModel.nearbyCount
                    ) { topic in
                        viewModel.pendingTopic = topic
                    }

                    if !viewModel.liveParties.isEmpty {
                        HomeLivePartiesSection(
                            parties: viewModel.liveParties,
                            statusLine: viewModel.statusLine,
                            isYourTurn: viewModel.isYourTurn,
                            onSelect: { party in
                                resumingParty = party
                            },
                            onLeave: viewModel.leave
                        )
                    }

                    HomePreviousPicksSection(recentPicks: viewModel.recentPicks) {
                        viewModel.showProfileFromPicks = true
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .refreshable {
                viewModel.refresh()
            }
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
