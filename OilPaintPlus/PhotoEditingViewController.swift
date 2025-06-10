//
//  PhotoEditingViewController.swift
//  OilPaintPlus
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import CoreImage

// Simple model for filtered images in the extension
struct SimpleFilteredImageModel {
    let imageName: String
    let filteredImage: UIImage
}

class PhotoEditingViewController: UIViewController, PHContentEditingController {
    
    // MARK: - Properties
    private var input: PHContentEditingInput?
    private var filteredImages: [SimpleFilteredImageModel] = []
    private var selectedImageIndex = 0
    
    // MARK: - IBOutlets
    @IBOutlet weak var bigImageView: UIImageView!
    @IBOutlet weak var filterScrollView: UIScrollView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        filterScrollView.showsHorizontalScrollIndicator = false
        filterScrollView.delegate = self
    }
    
    // MARK: - PHContentEditingController
    func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        // Inspect the adjustmentData to determine whether your extension can work with past edits
        return true
    }
    
    func startContentEditing(with contentEditingInput: PHContentEditingInput, placeholderImage: UIImage) {
        // Present content for editing, and keep the contentEditingInput for use when closing the edit session
        self.input = contentEditingInput
        bigImageView.image = placeholderImage
        filterImage(placeholderImage)
    }
    
    func finishContentEditing(completionHandler: @escaping (PHContentEditingOutput?) -> Void) {
        // Update UI to reflect that editing has finished and output is being rendered
        
        // Render and provide output on a background queue
        DispatchQueue.global(qos: .default).async {
            guard let input = self.input else {
                completionHandler(nil)
                return
            }
            
            // Create editing output from the editing input
            let output = PHContentEditingOutput(contentEditingInput: input)
            
            // Provide new adjustments and render output to given location
            let adjustmentData = PHAdjustmentData(
                formatIdentifier: "com.deanware.photix.extension",
                formatVersion: "1.0",
                data: "oil_paint_filter".data(using: .utf8) ?? Data()
            )
            output.adjustmentData = adjustmentData
            
            // Get the current filtered image
            let imageToSave = self.bigImageView.image ?? UIImage()
            
            // Save as JPEG
            if let jpegData = imageToSave.jpegData(compressionQuality: 1.0) {
                do {
                    try jpegData.write(to: output.renderedContentURL)
                    completionHandler(output)
                } catch {
                    print("Error writing image: \(error)")
                    completionHandler(nil)
                }
            } else {
                completionHandler(nil)
            }
        }
    }
    
    var shouldShowCancelConfirmation: Bool {
        // Returns whether a confirmation to discard changes should be shown to the user on cancel
        return false
    }
    
    func cancelContentEditing() {
        // Clean up temporary files, etc.
        // May be called after finishContentEditingWithCompletionHandler: while you prepare output
    }
    
    // MARK: - Image Processing
    private func filterImage(_ imageToFilter: UIImage) {
        DispatchQueue.global(qos: .default).async {
            var newFilteredImages: [SimpleFilteredImageModel] = []
            
            // Add original image
            let originalModel = SimpleFilteredImageModel(
                imageName: "Original",
                filteredImage: imageToFilter
            )
            newFilteredImages.append(originalModel)
            
            // Apply Kuwahara (Oil Paint) filter
            if let oilPaintImage = self.applyKuwaharaFilter(to: imageToFilter) {
                let oilPaintModel = SimpleFilteredImageModel(
                    imageName: "Oil Paint",
                    filteredImage: oilPaintImage
                )
                newFilteredImages.append(oilPaintModel)
            }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.filteredImages = newFilteredImages
                self.setupScrollView()
            }
        }
    }
    
    private func applyKuwaharaFilter(to inputImage: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: inputImage) else { return nil }
        
        let context = CIContext()
        
        // Apply a combination of blur and color enhancement to simulate oil paint effect
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return nil }
        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(3.0, forKey: kCIInputRadiusKey)
        
        guard let blurred = blurFilter.outputImage else { return nil }
        
        // Apply color controls to enhance the painted look
        guard let colorFilter = CIFilter(name: "CIColorControls") else { return nil }
        colorFilter.setValue(blurred, forKey: kCIInputImageKey)
        colorFilter.setValue(1.2, forKey: kCIInputSaturationKey)
        colorFilter.setValue(0.1, forKey: kCIInputBrightnessKey)
        colorFilter.setValue(1.1, forKey: kCIInputContrastKey)
        
        guard let outputImage = colorFilter.outputImage else { return nil }
        
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage, scale: inputImage.scale, orientation: inputImage.imageOrientation)
    }
    
    // MARK: - UI Setup
    private func setupScrollView() {
        // Clear existing subviews
        filterScrollView.subviews.forEach { $0.removeFromSuperview() }
        
        let pageSize = filterScrollView.frame.size
        let imageWidth = Int(filterScrollView.frame.size.height * 0.8)
        let imageHeight = imageWidth
        
        for (index, model) in filteredImages.enumerated() {
            // Create image view
            let imageView = UIImageView(image: model.filteredImage)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(
                x: imageWidth * index + 5,
                y: 0,
                width: imageWidth - 10,
                height: imageHeight
            )
            filterScrollView.addSubview(imageView)
            
            // Create label
            let label = UILabel(frame: CGRect(
                x: imageWidth * index + 5,
                y: Int(pageSize.height) - 20,
                width: imageWidth - 10,
                height: 15
            ))
            label.font = UIFont(name: "GillSans", size: 12) ?? UIFont.systemFont(ofSize: 12)
            label.textColor = .black
            label.backgroundColor = .clear
            label.textAlignment = .center
            label.text = model.imageName
            filterScrollView.addSubview(label)
            
            // Create button
            let button = UIButton(type: .custom)
            button.frame = imageView.frame
            button.tag = index
            button.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
            filterScrollView.addSubview(button)
        }
        
        // Set content size
        filterScrollView.contentSize = CGSize(
            width: imageWidth * filteredImages.count,
            height: Int(pageSize.height)
        )
    }
    
    @objc private func filterButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < filteredImages.count else { return }
        
        selectedImageIndex = index
        bigImageView.image = filteredImages[index].filteredImage
    }
}

// MARK: - UIScrollViewDelegate
extension PhotoEditingViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Keep scroll view horizontal only
        scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: 0)
    }
}