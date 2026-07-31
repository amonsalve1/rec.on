//
//  PartyInvitePage.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/3/2024.
//

import SwiftUI
import UIKit
import Combine

/// The second party setup page: share the code and watch people arrive.
/// Entering someone else's code lives on the home screen, not here — this is
/// your party, and offering to join a different one from inside it meant
/// creating a party just to leave it.
struct PartyInvitePage: View {

    // MARK: - Properties

    @ObservedObject var viewModel: PartySetupView.ViewModel

    @State private var copied = false

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            copyLinkButton

            participantList

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .alert("Code copied", isPresented: $copied) {
            Button("OK", role: .cancel) { }
        }
        .onAppear {
            viewModel.refreshParticipants()
            viewModel.ensureInviteCode()
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

    private var copyLinkButton: some View {
        Button {
            copyInviteLink()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(Constants.Fonts.iconSmall)

                Text(copyButtonTitle)
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

    private var copyButtonTitle: String {
        viewModel.inviteCode.map { "Copy code: \($0)" } ?? "Copy invite code"
    }

    private func copyInviteLink() {
        guard let code = viewModel.inviteCode else { return }

        UIPasteboard.general.string = code
        copied = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
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
