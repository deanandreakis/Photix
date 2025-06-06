//
//  CameraPreviewView.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let captureSession: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.configure(with: captureSession)
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Updates handled by the preview layer
    }
}

class CameraPreviewUIView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    func configure(with captureSession: AVCaptureSession) {
        guard let previewLayer = layer as? AVCaptureVideoPreviewLayer else {
            return
        }
        
        previewLayer.session = captureSession
        previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer = previewLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}