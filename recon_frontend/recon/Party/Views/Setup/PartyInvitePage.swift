//
//  PartyInvitePage.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/3/2024.
//

import SwiftUI
import UIKit
import Combine

/// The second party setup page, where the host shares the invite link, other
/// users join via a pasted link, and the current participants are listed.
struct PartyInvitePage: View {

    // MARK: - Properties

    @ObservedObject var viewModel: PartySetupView.ViewModel

    @State private var copied = false
    @State private var search = ""
    @State private var join = false
    @State private var joinErr = false
    @State private var err = ""

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            searchBar

            copyLinkButton

            participantList

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .alert("Link copied", isPresented: $copied) {
            Button("OK", role: .cancel) { }
        }
        .alert("Join Error", isPresented: $joinErr) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(err)
        }
        .onAppear {
            viewModel.refreshParticipants()
        }
        .onReceive(Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()) { _ in
            viewModel.refreshParticipants()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome to\nthe party!")
                    .font(Constants.Fonts.display)
                    .foregroundColor(.black)

                Text("Invite the gang!")
                    .font(Constants.Fonts.bodyRegularRounded)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("🎉")
                .font(.system(size: 40))
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            TextField("Paste invite link or search for users...", text: $search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit {
                    handleSearchOrJoin()
                }
                .font(Constants.Fonts.bodyRegularRounded)
                .foregroundColor(search.isEmpty ? .secondary : .primary)

            Spacer()

            if !search.isEmpty && !isJoinLink(search) {
                clearButton
            }

            searchAccessory
        }
        .padding(12)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var clearButton: some View {
        Button {
            search = ""
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.secondary)
                .font(Constants.Fonts.body)
        }
    }

    @ViewBuilder private var searchAccessory: some View {
        if isJoinLink(search) && !join {
            joinButton
        } else if join {
            ProgressView()
                .scaleEffect(0.8)
        } else {
            Image(systemName: search.isEmpty ? "link" : "magnifyingglass")
                .foregroundColor(.secondary)
        }
    }

    private var joinButton: some View {
        Button {
            handleSearchOrJoin()
        } label: {
            Text("Join")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Constants.Colors.orangePrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
    }

    private var copyLinkButton: some View {
        Button {
            copyInviteLink()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(Constants.Fonts.iconSmall)

                Text("Copy link to party")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                Capsule().fill(
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
    }

    private var participantList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.participants) { participant in
                PartyMemberRow(
                    name: participant.username ?? "User \(participant.id)",
                    avatar: avatarFor(participant),
                    statusText: statusFor(participant),
                    statusColor: statusColorFor(participant)
                )
            }
        }
    }

    // MARK: - Helpers

    private func avatarFor(_ participant: ParticipantDTO) -> String {
        let avatars = ["cat_avatar", "friend1", "friend2", "friend3"]
        return avatars[participant.id % avatars.count]
    }

    private func statusFor(_ participant: ParticipantDTO) -> String {
        if let session = viewModel.session, session.createdBy == participant.id {
            return "Host"
        }
        return "Ready"
    }

    private func statusColorFor(_ participant: ParticipantDTO) -> Color {
        if let session = viewModel.session, session.createdBy == participant.id {
            return Constants.Colors.orangePrimary
        }
        return Constants.Colors.orangePrimary
    }

    private func isJoinLink(_ text: String) -> Bool {
        if text.contains("/join/") || text.contains("/join") {
            return true
        }
        if Int(text.trimmingCharacters(in: .whitespaces)) != nil {
            return true
        }
        return false
    }

    private func extractSessionId(from text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)

        if let id = Int(trimmed) {
            return id
        }

        var urlString = trimmed
        if !urlString.contains("://") {
            urlString = "http://\(urlString)"
        }

        guard let url = URL(string: urlString) else {
            return nil
        }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        for (i, component) in pathComponents.enumerated() {
            if component == "join" || component.hasPrefix("join") {
                if i > 0, let id = Int(pathComponents[i - 1]) {
                    return id
                }
            }
        }

        for component in pathComponents {
            if let id = Int(component) {
                return id
            }
        }

        return nil
    }

    private func handleSearchOrJoin() {
        guard !search.isEmpty else { return }

        if let id = extractSessionId(from: search) {
            joinSession(sessionId: id)
        }
    }

    private func joinSession(sessionId: Int) {
        join = true
        err = ""

        viewModel.joinSession(sessionId: sessionId) { success in
            DispatchQueue.main.async {
                join = false
                if success {
                    search = ""
                    viewModel.refreshParticipants()
                } else {
                    err = "Failed to join session. Please check the link and try again."
                    joinErr = true
                }
            }
        }
    }

    private func copyInviteLink() {
        if let link = viewModel.inviteLinkString {
            UIPasteboard.general.string = link
            copied = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else {
            err = "Session not created yet. Please select a topic first."
            joinErr = true
        }
    }

}

/// A single participant row showing an avatar, name, and status pill.
struct PartyMemberRow: View {

    // MARK: - Properties

    let name: String
    let avatar: String
    let statusText: String
    let statusColor: Color

    // MARK: - UI

    var body: some View {
        HStack(spacing: 14) {
            Image(avatar)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())

            Text(name)
                .font(Constants.Fonts.bodySemibold)

            Spacer()

            Text(statusText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(statusColor)
                )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

}

#Preview {
    PartyInvitePage(viewModel: PartySetupView.ViewModel())
}
