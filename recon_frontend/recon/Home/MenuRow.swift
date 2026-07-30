//
//  MenuRow.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

/// A single icon-and-title row inside the side menu.
struct MenuRow: View {

    // MARK: - Properties

    let systemName: String
    let title: String

    // MARK: - UI

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .font(Constants.Fonts.icon)

            Text(title)
                .font(Constants.Fonts.bodyRounded)
        }
    }

}

#Preview {
    MenuRow(systemName: "gearshape", title: "Settings")
}
