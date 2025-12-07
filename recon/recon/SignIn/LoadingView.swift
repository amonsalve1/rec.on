//
//  LoadingView.swift
//  recon
//
//  Created by Ethan Chen on 11/28/2024.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image("RecOnLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            VStack(spacing: 12) {
                Text("Logging you in...")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 0.14, green: 0.14, blue: 0.14))
                    .padding(.top, 32)
                
                Text("This may take a moment")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color.gray)
            }
            
            Spacer()
        }
    }
}

