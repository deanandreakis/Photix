//
//  AccessibilitySupport.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - Accessibility Modifiers

extension View {
    func accessibleButton(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        isSelected: Bool = false
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
    
    func accessibleImage(
        label: String,
        isDecorative: Bool = false
    ) -> some View {
        if isDecorative {
            return self.accessibilityHidden(true)
        } else {
            return self
                .accessibilityLabel(label)
                .accessibilityAddTraits(.isImage)
        }
    }
    
    func accessibleSlider(
        label: String,
        value: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityHint(hint ?? "")
            .accessibilityAdjustableAction { direction in
                // Handle adjustable action
            }
    }
    
    func accessibleProgress(
        label: String,
        value: Double,
        total: Double = 1.0
    ) -> some View {
        let percentage = Int((value / total) * 100)
        return self
            .accessibilityLabel(label)
            .accessibilityValue("\(percentage) percent complete")
            .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - VoiceOver Announcements

@MainActor
class VoiceOverManager: ObservableObject {
    static let shared = VoiceOverManager()
    
    private init() {}
    
    func announce(_ message: String, priority: UIAccessibility.Notification = .announcement) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(notification: priority, argument: message)
        }
    }
    
    func announceFilterSelection(_ filterName: String) {
        announce("\(filterName) filter selected")
    }
    
    func announceProcessingProgress(_ percentage: Int, filterName: String? = nil) {
        if let filterName = filterName {
            announce("Processing \(filterName) filter, \(percentage) percent complete")
        } else {
            announce("Processing \(percentage) percent complete")
        }
    }
    
    func announceCompletion(_ message: String = "Processing complete") {
        announce(message, priority: .announcement)
    }
    
    func announceError(_ error: String) {
        announce("Error: \(error)", priority: .announcement)
    }
}

// MARK: - Accessibility-Enhanced Views

struct AccessibleFilterThumbnail: View {
    let filter: FilteredImage
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(uiImage: filter.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
                    .accessibleImage(
                        label: "Preview of \(filter.name) filter applied to image"
                    )
                
                Text(filter.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .blue : .primary)
                    .lineLimit(1)
                    .accessibilityHidden(true) // Already included in button label
            }
        }
        .accessibleButton(
            label: "\(filter.name) filter",
            hint: isSelected ? "Currently selected filter" : "Double tap to apply this filter",
            isSelected: isSelected
        )
        .onTapGesture {
            onTap()
            VoiceOverManager.shared.announceFilterSelection(filter.name)
        }
    }
}

struct AccessibleCameraControls: View {
    let onCapture: () -> Void
    let onSwitchCamera: () -> Void
    let onToggleFlash: () -> Void
    let isFlashEnabled: Bool
    
    var body: some View {
        HStack(spacing: 40) {
            // Photo library button
            Button(action: {}) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "photo.on.rectangle")
                            .foregroundColor(.white)
                    }
            }
            .accessibleButton(
                label: "Photo library",
                hint: "Open photo library to select an image"
            )
            
            // Capture button
            Button(action: {
                onCapture()
                VoiceOverManager.shared.announce("Photo captured")
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
            .accessibleButton(
                label: "Capture photo",
                hint: "Double tap to take a photo"
            )
            
            // Flash toggle
            Button(action: {
                onToggleFlash()
                VoiceOverManager.shared.announce(isFlashEnabled ? "Flash enabled" : "Flash disabled")
            }) {
                Image(systemName: isFlashEnabled ? "bolt.fill" : "bolt.slash.fill")
                    .font(.title2)
                    .foregroundColor(isFlashEnabled ? .yellow : .white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .accessibleButton(
                label: isFlashEnabled ? "Flash on" : "Flash off",
                hint: "Double tap to toggle flash"
            )
        }
    }
}

struct AccessibleProgressView: View {
    let progress: Double
    let label: String
    let currentStep: String?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .accessibleProgress(
                    label: label,
                    value: progress
                )
            
            if let currentStep = currentStep {
                Text(currentStep)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Current step: \(currentStep)")
            }
        }
    }
}

// MARK: - Dynamic Type Support

struct ScaledFont: ViewModifier {
    let font: UIFont
    let maximumSize: CGFloat?
    
    init(_ font: UIFont, maximumSize: CGFloat? = nil) {
        self.font = font
        self.maximumSize = maximumSize
    }
    
    func body(content: Content) -> some View {
        content
            .font(Font(font))
            .dynamicTypeSize(.small ... .accessibility3)
    }
}

extension View {
    func scaledFont(_ font: UIFont, maximumSize: CGFloat? = nil) -> some View {
        modifier(ScaledFont(font, maximumSize: maximumSize))
    }
}

// MARK: - Reduced Motion Support

struct ReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation
    let reducedAnimation: Animation
    
    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? reducedAnimation : animation, value: UUID())
    }
}

extension View {
    func respectsReducedMotion(
        animation: Animation = .easeInOut,
        reducedAnimation: Animation = .linear(duration: 0.1)
    ) -> some View {
        modifier(ReducedMotionModifier(
            animation: animation,
            reducedAnimation: reducedAnimation
        ))
    }
}

// MARK: - High Contrast Support

struct HighContrastButton: View {
    let title: String
    let action: () -> Void
    let isDestructive: Bool
    
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    @Environment(\.accessibilityInvertColors) var invertColors
    
    init(
        _ title: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var foregroundColor: Color {
        if differentiateWithoutColor || invertColors {
            return .primary
        }
        return isDestructive ? .white : .white
    }
    
    private var backgroundColor: Color {
        if differentiateWithoutColor {
            return .clear
        }
        return isDestructive ? .red : .blue
    }
    
    private var borderColor: Color {
        if differentiateWithoutColor {
            return isDestructive ? .red : .blue
        }
        return .clear
    }
    
    private var borderWidth: CGFloat {
        return differentiateWithoutColor ? 2 : 0
    }
}

#Preview {
    VStack(spacing: 20) {
        AccessibleProgressView(
            progress: 0.6,
            label: "Processing Filters",
            currentStep: "Applying sepia filter"
        )
        
        HighContrastButton("Save Image") {}
        
        HighContrastButton("Delete", isDestructive: true) {}
    }
    .padding()
}