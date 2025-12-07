//
//  ProfileView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI
import Foundation
import UIKit

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let userId: Int?
    
    @AppStorage("userName") var storedName: String = ""
    @AppStorage("userLocation") var storedLocation: String = ""
    @AppStorage("userProfilePicturePath") var profilePicturePath: String = ""
    
    @State private var profile: LocalProfile?
    @State private var recentPicks: [FinalPick] = []
    @State private var isLoading = false
    @State private var isLoadingProfile = false
    @State private var errorMessage: String?
    @State private var showEditSheet = false
    
    var isOwnProfile: Bool {
        userId == nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                Color(red: 0.14, green: 0.14, blue: 0.14)
                    .frame(height: 200)
                    .ignoresSafeArea(edges: .top)
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(Color.orange)
                        .clipShape(Circle())
                }
                .padding(.leading, 24)
                .padding(.top, 16)
    
                VStack(spacing: 0) {
                    Spacer().frame(height: 120)
                    
                    ZStack(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center) {
                                Text(profile?.name ?? (storedName.isEmpty ? "User" : storedName))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                Button(action: {
                                    guard isOwnProfile else { return }
                                    showEditSheet = true
                                }) {
                                    Text(isOwnProfile ? "Edit" : "Message")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 8)
                                        .background(Color.orange)
                                        .cornerRadius(18)
                                        .shadow(color: .black.opacity(0.25),
                                                radius: 4, x: 0, y: 2)
                                }
                            }
                            
                            HStack {
                                Text("\(profile?.friendsCount ?? 0) friends")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                let displayLocation = profile?.location ?? storedLocation
                                if !displayLocation.isEmpty {
                                    HStack(spacing: 6) {
                                        Image(systemName: "mappin.and.ellipse")
                                            .font(.subheadline)
                                            .foregroundColor(.orange)
                                        
                                        Text(displayLocation)
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 48)
                        .padding(.bottom, 16)
                        .background(Color(.systemBackground))
                        
                        Group {
                            if let imagePath = profile?.profilePictureUrl,
                               !imagePath.isEmpty,
                               let image = loadImage(from: imagePath) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else if !profilePicturePath.isEmpty,
                                      let image = loadImage(from: profilePicturePath) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: 4)
                        )
                        .offset(x: 24, y: -48)
                    }
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent picks")
                        .font(.system(size: 22, weight: .semibold))
                    
                    if isLoading && recentPicks.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if recentPicks.isEmpty {
                        Text("No recent picks yet")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .padding(.top, 8)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(recentPicks) { pick in
                                RecentPickCard(pick: pick)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showEditSheet) {
            EditProfileView(
                currentName: storedName,
                currentLocation: storedLocation,
                currentProfilePicturePath: profilePicturePath,
                onSave: { name, location, picturePath in
                    storedName = name
                    if !location.isEmpty {
                        storedLocation = location
                    } else {
                        storedLocation = ""
                    }
                    profilePicturePath = picturePath
                    Task {
                        await loadProfile()
                    }
                }
            )
        }
        .task {
            await loadProfile()
            await loadRecentPicks()
        }
    }
}

extension ProfileView {
    func loadProfile() async {
        guard !isLoadingProfile else { return }
        isLoadingProfile = true
        
        await MainActor.run {
            let picUrl = profilePicturePath.isEmpty ? nil : profilePicturePath
            self.profile = LocalProfile(
                name: storedName,
                location: storedLocation,
                friendsCount: 0,
                profilePictureUrl: picUrl
            )
            self.isLoadingProfile = false
        }
    }
    
    @MainActor
    func loadImage(from path: String) -> UIImage? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(path)
        
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    func loadRecentPicks() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        await MainActor.run {
            if let data = UserDefaults.standard.data(forKey: "recentPicks") {
                if let decoded = try? JSONDecoder().decode([RecentPickData].self, from: data) {
                    self.recentPicks = decoded.map { data in
                        FinalPick(
                            id: data.id,
                            name: data.name,
                            imageUrl: data.imageUrl,
                            address: data.address,
                            tags: data.tags,
                            timeAgo: data.timeAgo
                        )
                    }
                } else {
                    self.recentPicks = []
                }
            } else {
                self.recentPicks = []
            }
            self.isLoading = false
        }
    }
}
