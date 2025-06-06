//
//  AsyncImageView.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI

struct AsyncImageView: View {
    let image: UIImage?
    let contentMode: ContentMode
    let placeholder: AnyView?
    
    init(
        image: UIImage?,
        contentMode: ContentMode = .fit,
        @ViewBuilder placeholder: () -> AnyView = { AnyView(Color.gray.opacity(0.3)) }
    ) {
        self.image = image
        self.contentMode = contentMode
        self.placeholder = placeholder()
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder
            }
        }
    }
}

#Preview {
    AsyncImageView(
        image: UIImage(systemName: "photo"),
        contentMode: .fit
    ) {
        AnyView(
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Text("No Image")
                        .foregroundColor(.secondary)
                )
        )
    }
    .frame(width: 200, height: 200)
}