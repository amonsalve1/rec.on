//
//  MessageRow.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

struct MessageRow: View {
    let name: String
    let imageName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            Text(name)
                .font(.system(size: 17, weight: .regular, design: .rounded))
        }
    }
}

