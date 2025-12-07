//
//  MenuRow.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

struct MenuRow: View {
    let systemName: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .regular))
            Text(title)
                .font(.system(size: 18, weight: .regular, design: .rounded))
        }
    }
}

