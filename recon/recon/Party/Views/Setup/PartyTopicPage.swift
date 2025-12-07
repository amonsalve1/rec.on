//
//  PartyTopicPage.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/3/2024.
//

import SwiftUI

struct PartyTopicPage: View {
    let onTopicSelected: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top) {
                Text("What are you\nthinking?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Spacer()

                Text("🤔")
                    .font(.system(size: 40))
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Common picks")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))

                VStack(spacing: 10) {
                    TopicBtn(title: "Food nearby") {
                        onTopicSelected("food")
                    }
                    TopicBtn(title: "Study spots") {
                        onTopicSelected("study")
                    }
                    TopicBtn(title: "Movies") {
                        onTopicSelected("movie")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }
}

struct TopicBtn: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.75, blue: 0.4),
                            Color(red: 1.0, green: 0.55, blue: 0.35)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(18)
        }
        .buttonStyle(.plain)
    }
}
