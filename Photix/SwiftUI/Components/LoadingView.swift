//
//  LoadingView.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI

struct LoadingView: View {
    let message: String
    let backgroundColor: Color
    
    init(message: String = "Loading...", backgroundColor: Color = .black.opacity(0.3)) {
        self.message = message
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text(message)
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
}

#Preview {
    LoadingView(message: "Processing filters...")
}