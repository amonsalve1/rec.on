//
//  SideMenuView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

struct SideMenuView: View {
    let userName: String
    let profilePicturePath: String
    let onViewProfile: () -> Void
    let onSettings: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.68, blue: 0.30),
                        Color(red: 1.0, green: 0.58, blue: 0.30)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Image("SideMenuBlob")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 230)
                    .offset(x: 40, y: 40)
            }

            VStack(alignment: .leading, spacing: 24) {
                Button(action: {
                    onViewProfile()
                }) {
                    HStack(spacing: 12) {
                        Group {
                            if let image = loadProfileImage() {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(userName)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                            Text("View profile")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.black.opacity(0.7))
                        }
                    }
                }
                .buttonStyle(.plain)

                Divider().background(Color.black.opacity(0.2))

                VStack(alignment: .leading, spacing: 16) {
                    Button(action: {
                        onSettings()
                    }) {
                        MenuRow(systemName: "gearshape", title: "Settings")
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)

            Image("RecOnGlyph")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .padding(.bottom, 24)
        }
    }
    
    func loadProfileImage() -> UIImage? {
        guard !profilePicturePath.isEmpty else { return nil }
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imageURL = documentsPath.appendingPathComponent(profilePicturePath)
        
        guard let imageData = try? Data(contentsOf: imageURL) else {
            return nil
        }
        return UIImage(data: imageData)
    }
}

struct SideMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuView(userName: "User", profilePicturePath: "", onViewProfile: {}, onSettings: {})
            .frame(width: 300)
    }
}
