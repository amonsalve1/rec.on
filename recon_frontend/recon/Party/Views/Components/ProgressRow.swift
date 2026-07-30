//
//  ProgressRow.swift
//  recon
//
//  Created by Ethan Chen on 12/5/2024.
//

import SwiftUI

/// A single row in the waiting screen showing one member's swipe progress.
struct ProgressRow: View {

    // MARK: - Properties

    let progress: ProgressDTO

    // MARK: - UI

    var body: some View {
        HStack {
            Text(progress.username)
                .font(Constants.Fonts.bodyMediumRounded)

            Spacer()

            Text("\(progress.swipe_count)/\(progress.total_options)")
                .font(Constants.Fonts.label)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 24)
    }

}

#Preview {
    ProgressRow(
        progress: ProgressDTO(
            user_id: 1,
            username: "Alex",
            swipe_count: 4,
            total_options: 10
        )
    )
    .padding()
    .background(Constants.Colors.background)
}
