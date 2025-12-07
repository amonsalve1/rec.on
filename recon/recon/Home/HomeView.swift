//
//  HomeView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI
import Combine

struct HomeView: View {
    @State private var showMenu = false
    @State private var showProfile = false
    @State private var showProfileFromPicks = false
    @State private var showEditProfile = false

    @AppStorage("userName") var userName: String = ""
    @AppStorage("userLocation") var userLocation: String = ""
    @AppStorage("userProfilePicturePath") var profilePicturePath: String = ""
    
    @State private var recentPicks: [FinalPick] = []

    let friends: [Friend] = [
        .init(name: "Mei Mei", imageName: "friend1"),
        .init(name: "Larry", imageName: "friend2"),
        .init(name: "Milly", imageName: "friend3"),
        .init(name: "Uni", imageName: "friend4")
    ]

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .trailing) {
                    ZStack(alignment: .bottom) {
                        Color(.systemGray6).ignoresSafeArea()

                        ScrollView {
                            VStack(spacing: 24) {
                                HomeHeaderView(
                                    userName: userName,
                                    profilePicturePath: profilePicturePath,
                                    onMenuTap: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                            showMenu.toggle()
                                        }
                                    }
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, -16)

                                VStack(spacing: 24) {
                                    HomeSoloPartySection()
                                    HomeFriendsSection(friends: friends)
                                    HomePreviousPicksSection(recentPicks: recentPicks) {
                                        showProfileFromPicks = true
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        VStack {
                            Spacer()
                            Image("RecOnGlyph")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .padding(.bottom, 20)
                        }
                    }

                    ZStack(alignment: .trailing) {
                        Color.black
                            .opacity(showMenu ? 0.65 : 0)
                            .ignoresSafeArea()
                            .animation(.easeInOut(duration: 0.25), value: showMenu)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                    showMenu = false
                                }
                            }
                            .allowsHitTesting(showMenu)

                        SideMenuView(
                            userName: userName.isEmpty ? "User" : userName,
                            profilePicturePath: profilePicturePath,
                            onViewProfile: {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                    showMenu = false
                                }
                                showProfile = true
                            },
                            onSettings: {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                    showMenu = false
                                }
                                showEditProfile = true
                            }
                        )
                        .frame(width: geo.size.width * 0.7)
                        .offset(x: showMenu ? 0 : geo.size.width * 0.7)
                        .animation(
                            .spring(response: 0.55, dampingFraction: 0.85)
                                .delay(0.03),
                            value: showMenu
                        )
                    }
                    .zIndex(1)
                }
            }
            .fullScreenCover(isPresented: $showProfile) {
                ProfileView(userId: nil)
            }
            .fullScreenCover(isPresented: $showProfileFromPicks) {
                ProfileView(userId: nil)
            }
            .sheet(isPresented: $showEditProfile) {
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
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                loadRecentPicks()
            }
            .onAppear {
                loadRecentPicks()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecentPicksUpdated"))) { _ in
                loadRecentPicks()
            }
        }
    }
    
    func loadRecentPicks() {
        guard let data = UserDefaults.standard.data(forKey: "recentPicks") else {
            recentPicks = []
            return
        }
        
        if let decoded = try? JSONDecoder().decode([RecentPickData].self, from: data) {
            recentPicks = decoded.map { pickData in
                FinalPick(
                    id: pickData.id,
                    name: pickData.name,
                    imageUrl: pickData.imageUrl,
                    address: pickData.address,
                    tags: pickData.tags,
                    timeAgo: pickData.timeAgo
                )
            }
        } else {
            recentPicks = []
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
