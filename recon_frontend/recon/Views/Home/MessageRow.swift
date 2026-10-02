//
//  MessageRow.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

/// An avatar-and-name row for message lists.
struct MessageRow: View {

    // MARK: - Properties

    let name: String
    let imageName: String

    // MARK: - Constants

    private let avatarSize: CGFloat = 36

    // MARK: - UI

    var body: some View {
        HStack(spacing: 12) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())

            Text(name)
                .font(Constants.Fonts.rowTitle)
        }
    }

}

#Preview {
    MessageRow(name: "Mei Mei", imageName: "friend1")
}
