//
//  ProgressRow.swift
//  recon
//
//  Created by Ethan Chen on 12/5/2024.
//

import SwiftUI

struct ProgressRow: View {
    let progress: ProgressDTO
    
    var body: some View {
        HStack {
            Text(progress.username)
                .font(.system(size: 16, weight: .medium, design: .rounded))
            
            Spacer()
            
            Text("\(progress.swipe_count)/\(progress.total_options)")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 24)
    }
}

