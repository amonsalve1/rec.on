//
//  PartyInvitePage.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/3/2024.
//

import SwiftUI
import UIKit
import Combine

struct PartyInvitePage: View {
    @ObservedObject var viewModel: PartyViewModel
    @State private var copied = false
    @State private var search = ""
    @State private var join = false
    @State private var joinErr = false
    @State private var err = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to\nthe party!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.black)

                    Text("Invite the gang!")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("🎉")
                    .font(.system(size: 40))
            }

            HStack(spacing: 8) {
                TextField("Paste invite link or search for users...", text: $search)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit {
                        handleSearchOrJoin()
                    }
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(search.isEmpty ? .secondary : .primary)
                
                Spacer()
                
                if !search.isEmpty && !isJoinLink(search) {
                    Button(action: {
                        search = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                }
                
                if isJoinLink(search) && !join {
                    Button(action: {
                        handleSearchOrJoin()
                    }) {
                        Text("Join")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.35))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                } else if join {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: search.isEmpty ? "link" : "magnifyingglass")
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

            Button {
                copyInviteLink()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 16, weight: .semibold))
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
                                Color(red: 1.0, green: 0.75, blue: 0.4),
                                Color(red: 1.0, green: 0.55, blue: 0.35)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                )
            }

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
            return Color(red: 1.0, green: 0.55, blue: 0.35)
        }
        return Color(red: 1.0, green: 0.55, blue: 0.35)
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

struct PartyMemberRow: View {
    let name: String
    let avatar: String
    let statusText: String
    let statusColor: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(avatar)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())

            Text(name)
                .font(.system(size: 18, weight: .semibold, design: .rounded))

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
