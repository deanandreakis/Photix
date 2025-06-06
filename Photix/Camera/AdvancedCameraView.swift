//
//  AdvancedCameraView.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI
import AVFoundation

struct AdvancedCameraView: View {
    @State private var cameraManager = CameraManager()
    @Environment(\.dismiss) private var dismiss
    
    let onImageCaptured: (UIImage) -> Void
    
    @State private var showingCapturedImage = false
    @State private var dragOffset: CGSize = .zero
    @State private var lastZoomFactor: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview
                if cameraManager.isSessionRunning {
                    CameraPreviewView(captureSession: cameraManager.captureSession)
                        .ignoresSafeArea()
                        .onTapGesture(count: 2) {
                            // Double tap to switch camera
                            Task {
                                await cameraManager.switchCamera()
                            }
                        }
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let newZoom = lastZoomFactor * value
                                    cameraManager.setZoomFactor(newZoom)
                                }
                                .onEnded { value in
                                    lastZoomFactor = cameraManager.zoomFactor
                                }
                        )
                } else {
                    Color.black
                        .ignoresSafeArea()
                        .overlay {
                            if let error = cameraManager.captureError {
                                VStack(spacing: 16) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Text(error.localizedDescription)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    Button("Settings") {
                                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(settingsUrl)
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            } else {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                        }
                }
                
                // Camera controls overlay
                VStack {
                    // Top controls
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Flash toggle
                        if cameraManager.currentVideoDevice?.hasFlash == true {
                            Button(action: {
                                cameraManager.toggleFlash()
                                HapticManager.shared.impact(.light)
                            }) {
                                Image(systemName: cameraManager.isFlashEnabled ? "bolt.fill" : "bolt.slash.fill")
                                    .font(.title2)
                                    .foregroundColor(cameraManager.isFlashEnabled ? .yellow : .white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                        }
                        
                        // Camera switch
                        Button(action: {
                            Task {
                                await cameraManager.switchCamera()
                                HapticManager.shared.impact(.medium)
                            }
                        }) {
                            Image(systemName: "camera.rotate.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Zoom indicator
                    if cameraManager.zoomFactor > 1.1 {
                        Text("\(cameraManager.zoomFactor, specifier: "%.1f")x")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Capsule())
                            .transition(.opacity.combined(with: .scale))
                    }
                    
                    Spacer()
                    
                    // Bottom controls
                    HStack(spacing: 40) {
                        // Photo library thumbnail
                        Button(action: {
                            // Open photo library
                        }) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    Image(systemName: "photo.on.rectangle")
                                        .foregroundColor(.white)
                                }
                        }
                        
                        // Capture button
                        Button(action: {
                            cameraManager.capturePhoto()
                            HapticManager.shared.impact(.heavy)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 90, height: 90)
                            }
                        }
                        .scaleEffect(cameraManager.isSessionRunning ? 1.0 : 0.8)
                        .animation(.easeInOut(duration: 0.2), value: cameraManager.isSessionRunning)
                        
                        // Settings/filters
                        Button(action: {
                            // Open camera settings
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.capturedImage) { newImage in
            if let image = newImage {
                onImageCaptured(image)
                dismiss()
            }
        }
        .sheet(isPresented: $showingCapturedImage) {
            if let image = cameraManager.capturedImage {
                CapturedImagePreview(image: image) { shouldKeep in
                    if shouldKeep {
                        onImageCaptured(image)
                        dismiss()
                    } else {
                        cameraManager.capturedImage = nil
                        showingCapturedImage = false
                    }
                }
            }
        }
    }
}

struct CapturedImagePreview: View {
    let image: UIImage
    let onDecision: (Bool) -> Void
    
    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack(spacing: 40) {
                Button("Retake") {
                    onDecision(false)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                
                Button("Use Photo") {
                    onDecision(true)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .background(Color.black)
    }
}

#Preview {
    AdvancedCameraView { _ in }
}