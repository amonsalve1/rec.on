//
//  LogoTitleView.swift
//  recon
//
//  Created by Anatoli Monsalve on 12/5/2024.
//

import SwiftUI

struct LogoTitleView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image("RecOnMarkColored")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)

            Text("Rec.On")
                .font(.system(size: 28, weight: .bold, design: .rounded))
        }
    }
}
