//
//  HomeHeaderView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI
import UIKit

struct HomeHeaderView: View {
    let userName: String
    let profilePicturePath: String
    let onMenuTap: () -> Void
    
    var body: some View {
        ZStack {
            HStack {
                Text("Hi \(userName.isEmpty ? "User" : userName)!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)

                Spacer()

                Button {
                    onMenuTap()
                } label: {
                    Group {
                        if let image = loadProfileImage() {
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
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func loadProfileImage() -> UIImage? {
        guard !profilePicturePath.isEmpty else { return nil }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(profilePicturePath)
        
        guard let data = try? Data(contentsOf: url),
              let img = UIImage(data: data) else {
            return nil
        }
        return img
    }
}

