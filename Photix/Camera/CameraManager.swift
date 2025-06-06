//
//  CameraManager.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import AVFoundation
import UIKit
import SwiftUI
import Combine

@MainActor
class CameraManager: NSObject, ObservableObject {
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var photoOutput = AVCapturePhotoOutput()
    
    @Published var isSessionRunning = false
    @Published var isFlashEnabled = false
    @Published var currentCameraPosition: AVCaptureDevice.Position = .back
    @Published var zoomFactor: CGFloat = 1.0
    @Published var maxZoomFactor: CGFloat = 1.0
    
    @Published var capturedImage: UIImage?
    @Published var captureError: CameraError?
    
    var currentVideoDevice: AVCaptureDevice?
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    enum CameraError: Error, LocalizedError {
        case noCameraAvailable
        case cannotAddInput
        case cannotAddOutput
        case captureSessionNotRunning
        case photoCaptureFailed
        case permissionDenied
        
        var errorDescription: String? {
            switch self {
            case .noCameraAvailable:
                return "No camera available on this device"
            case .cannotAddInput:
                return "Cannot add camera input to capture session"
            case .cannotAddOutput:
                return "Cannot add photo output to capture session"
            case .captureSessionNotRunning:
                return "Camera session is not running"
            case .photoCaptureFailed:
                return "Failed to capture photo"
            case .permissionDenied:
                return "Camera permission denied"
            }
        }
    }
    
    override init() {
        super.init()
        Task {
            await requestCameraPermission()
        }
    }
    
    func requestCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            await setupCaptureSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                await setupCaptureSession()
            } else {
                captureError = .permissionDenied
            }
        case .denied, .restricted:
            captureError = .permissionDenied
        @unknown default:
            captureError = .permissionDenied
        }
    }
    
    func setupCaptureSession() async {
        captureSession.beginConfiguration()
        
        // Set session preset
        if captureSession.canSetSessionPreset(.photo) {
            captureSession.sessionPreset = .photo
        }
        
        // Add video input
        do {
            try await addVideoInput()
            try await addPhotoOutput()
            
            captureSession.commitConfiguration()
            
            // Start session on background queue
            Task.detached { [captureSession = self.captureSession] in
                captureSession.startRunning()
                await MainActor.run { [weak self] in
                    self?.isSessionRunning = true
                }
            }
        } catch {
            captureSession.commitConfiguration()
            if let cameraError = error as? CameraError {
                captureError = cameraError
            } else {
                captureError = .cannotAddInput
            }
        }
    }
    
    private func addVideoInput() async throws {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition) else {
            throw CameraError.noCameraAvailable
        }
        
        let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
        
        if captureSession.canAddInput(videoDeviceInput) {
            captureSession.addInput(videoDeviceInput)
            self.videoDeviceInput = videoDeviceInput
            self.currentVideoDevice = videoDevice
            
            // Set max zoom factor
            maxZoomFactor = min(videoDevice.activeFormat.videoMaxZoomFactor, 6.0)
        } else {
            throw CameraError.cannotAddInput
        }
    }
    
    private func addPhotoOutput() async throws {
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            
            // Configure photo output
            photoOutput.isHighResolutionCaptureEnabled = true
            if #available(iOS 17.0, *) {
                photoOutput.maxPhotoQualityPrioritization = .quality
            }
        } else {
            throw CameraError.cannotAddOutput
        }
    }
    
    func capturePhoto() {
        guard captureSession.isRunning else {
            captureError = .captureSessionNotRunning
            return
        }
        
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        
        // Configure flash
        if currentVideoDevice?.hasFlash == true {
            settings.flashMode = isFlashEnabled ? .on : .off
        }
        
        // Capture photo
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func switchCamera() async {
        let newPosition: AVCaptureDevice.Position = currentCameraPosition == .back ? .front : .back
        
        guard let newVideoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            return
        }
        
        do {
            let newVideoDeviceInput = try AVCaptureDeviceInput(device: newVideoDevice)
            
            captureSession.beginConfiguration()
            
            if let currentInput = videoDeviceInput {
                captureSession.removeInput(currentInput)
            }
            
            if captureSession.canAddInput(newVideoDeviceInput) {
                captureSession.addInput(newVideoDeviceInput)
                videoDeviceInput = newVideoDeviceInput
                currentVideoDevice = newVideoDevice
                currentCameraPosition = newPosition
                
                // Update max zoom factor
                maxZoomFactor = min(newVideoDevice.activeFormat.videoMaxZoomFactor, 6.0)
                zoomFactor = 1.0
            }
            
            captureSession.commitConfiguration()
        } catch {
            print("Error switching camera: \(error)")
        }
    }
    
    func setZoomFactor(_ factor: CGFloat) {
        guard let device = currentVideoDevice else { return }
        
        let clampedZoom = max(1.0, min(factor, maxZoomFactor))
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clampedZoom
            device.unlockForConfiguration()
            zoomFactor = clampedZoom
        } catch {
            print("Error setting zoom: \(error)")
        }
    }
    
    func toggleFlash() {
        isFlashEnabled.toggle()
    }
    
    func stopSession() {
        if captureSession.isRunning {
            Task.detached { [captureSession = self.captureSession] in
                captureSession.stopRunning()
                await MainActor.run { [weak self] in
                    self?.isSessionRunning = false
                }
            }
        }
    }
    
    func startSession() {
        if !captureSession.isRunning {
            Task.detached { [captureSession = self.captureSession] in
                captureSession.startRunning()
                await MainActor.run { [weak self] in
                    self?.isSessionRunning = true
                }
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("Photo capture error: \(error)")
                captureError = .photoCaptureFailed
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                captureError = .photoCaptureFailed
                return
            }
            
            capturedImage = image
        }
    }
}