//
//  ProfileView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI
import UIKit

/// The profile page: brand banner, avatar card with name and location, and
/// the list of recent picks.
struct ProfileView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ViewModel

    @AppStorage("userName") var storedName: String = ""
    @AppStorage("userLocation") var storedLocation: String = ""
    @AppStorage("userProfilePicturePath") var profilePicturePath: String = ""

    // MARK: - Constants

    private let bannerHeight: CGFloat = 200
    private let avatarSize: CGFloat = 96

    // MARK: - Init

    init(userId: Int?) {
        _viewModel = StateObject(wrappedValue: ViewModel(userId: userId))
    }

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            header

            picksList
        }
        .background(Constants.Colors.background)
        .sheet(isPresented: $viewModel.showEditSheet) {
            editProfileSheet
        }
        .task {
            viewModel.loadProfile(
                name: storedName,
                location: storedLocation,
                picturePath: profilePicturePath
            )
            viewModel.loadRecentPicks()
        }
    }

    private var header: some View {
        ZStack(alignment: .topLeading) {
            /// A near-black slab was the one dark surface in a warm app, and
            /// it read as a different product. The brand ramp is what every
            /// other full-bleed header here uses.
            Constants.Gradients.brand
                .frame(height: bannerHeight)
                .ignoresSafeArea(edges: .top)

            backButton

            VStack(spacing: 0) {
                Spacer().frame(height: 120)

                profileCard
            }
        }
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(Constants.Fonts.buttonLabel)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(Color.white.opacity(0.22))
                )
        }
        .padding(.leading, 24)
        .padding(.top, Constants.Padding.screenHorizontal)
    }

    private var profileCard: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 12) {
                nameRow

                statsRow
            }
            .padding(.horizontal, 24)
            .padding(.top, 48)
            .padding(.bottom, Constants.Padding.screenHorizontal)
            .background(Constants.Colors.background)

            avatar
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Constants.Colors.background, lineWidth: 4)
                )
                .offset(x: 24, y: -48)
        }
    }

    private var nameRow: some View {
        HStack(alignment: .center) {
            Text(displayName)
                .font(Constants.Fonts.heading)
                .foregroundColor(Constants.Colors.ink)

            Spacer()

            Button {
                guard viewModel.isOwnProfile else { return }
                viewModel.showEditSheet = true
            } label: {
                Text(viewModel.isOwnProfile ? "Edit" : "Message")
                    .font(Constants.Fonts.subheadlineSemibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(Constants.Gradients.brand)
                    )
            }
        }
    }

    private var statsRow: some View {
        HStack {
            Text((viewModel.profile?.friendsCount ?? 0).counted("friend"))
                .font(Constants.Fonts.subheadline)
                .foregroundColor(Constants.Colors.inkSecondary)

            Spacer()

            if !displayLocation.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(Constants.Fonts.subheadline)
                        .foregroundColor(Constants.Colors.orangePrimary)

                    Text(displayLocation)
                        .font(Constants.Fonts.subheadline)
                        .foregroundColor(Constants.Colors.ink)
                }
            }
        }
    }

    @ViewBuilder
    private var avatar: some View {
        if let imagePath = viewModel.profile?.profilePictureUrl,
           !imagePath.isEmpty,
           let image = viewModel.loadImage(from: imagePath) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if !profilePicturePath.isEmpty,
                  let image = viewModel.loadImage(from: profilePicturePath) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFill()
                .foregroundColor(Constants.Colors.controlDisabled)
        }
    }

    private var picksList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Recent picks")
                    .font(Constants.Fonts.sectionTitlePlain)

                picksContent
            }
            .padding(.top, Constants.Padding.screenHorizontal)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var picksContent: some View {
        if viewModel.isLoading && viewModel.recentPicks.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
        } else if viewModel.recentPicks.isEmpty {
            Text("No recent picks yet")
                .foregroundColor(Constants.Colors.inkSecondary)
                .font(Constants.Fonts.subheadline)
                .padding(.top, 8)
        } else {
            VStack(spacing: 16) {
                ForEach(viewModel.recentPicks) { pick in
                    RecentPickCard(pick: pick)
                }
            }
            .padding(.bottom, 24)
        }
    }

    private var editProfileSheet: some View {
        EditProfileView(
            currentName: storedName,
            currentLocation: storedLocation,
            currentProfilePicturePath: profilePicturePath,
            onSave: { name, location, picturePath in
                storedName = name
                storedLocation = location
                profilePicturePath = picturePath
                viewModel.loadProfile(
                    name: name,
                    location: location,
                    picturePath: picturePath
                )
            }
        )
    }

    // MARK: - Helpers

    /// The server sends an EMPTY name rather than omitting it for an account
    /// that never completed profile setup, so `??` never fired and the page
    /// rendered a blank line where the name goes. Empty counts as missing.
    private var displayName: String {
        let candidates = [viewModel.profile?.name, storedName]
        return candidates
            .compactMap { $0 }
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            ?? "User"
    }

    private var displayLocation: String {
        let candidates = [viewModel.profile?.location, storedLocation]
        return candidates
            .compactMap { $0 }
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            ?? ""
    }

}

#Preview {
    ProfileView(userId: nil)
}
