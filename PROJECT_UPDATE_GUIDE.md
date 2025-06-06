# Xcode Project Update Guide

## Overview
This guide explains how to update the existing Photix Xcode project to support the new Swift/SwiftUI implementation while maintaining compatibility with the existing Objective-C code.

## Required Updates

### 1. Xcode Project Settings

Open the project in Xcode and update these settings:

#### Project Settings:
- **iOS Deployment Target**: 16.0 (minimum for SwiftUI features)
- **Swift Version**: Swift 5.9 or later
- **Build Settings**:
  - `SWIFT_OBJC_BRIDGING_HEADER = Photix/Photix-Bridging-Header.h`
  - `SWIFT_VERSION = 5.9`
  - `IPHONEOS_DEPLOYMENT_TARGET = 16.0`
  - `ENABLE_PREVIEWS = YES` (for SwiftUI previews)

#### Capabilities:
Enable these capabilities in the project settings:
- **App Groups** (for widget/extension data sharing)
- **Background Modes**: Background processing
- **Live Activities**
- **Push Notifications** (for Live Activities)

### 2. Add New Files to Project

Add all the Swift files we created to the Xcode project:

#### Models:
- `Photix/Models/FilteredImage.swift`
- `Photix/Models/PhotoManager.swift`

#### Services:
- `Photix/Services/FilterProcessor.swift`
- `Photix/Services/DataManager.swift`
- `Photix/Services/StoreManager.swift`
- `Photix/Services/DependencyContainer.swift`

#### SwiftUI Views:
- `Photix/SwiftUI/PhotixApp.swift`
- `Photix/SwiftUI/Navigation/AppNavigation.swift`
- `Photix/SwiftUI/Views/ContentView.swift`
- `Photix/SwiftUI/Views/PhotoCaptureView.swift`
- `Photix/SwiftUI/Views/FilterSelectionView.swift`
- `Photix/SwiftUI/Views/PhotoEditView.swift`
- `Photix/SwiftUI/Views/SettingsView.swift`
- `Photix/SwiftUI/Views/CameraView.swift`

#### Camera System:
- `Photix/Camera/CameraManager.swift`
- `Photix/Camera/CameraPreviewView.swift`
- `Photix/Camera/AdvancedCameraView.swift`

#### Photo Management:
- `Photix/Photos/PhotoLibraryManager.swift`
- `Photix/Photos/PhotoPickerView.swift`

#### Rendering & Performance:
- `Photix/Rendering/MetalFilterRenderer.swift`
- `Photix/Rendering/RealtimeFilterView.swift`
- `Photix/Performance/ImageCache.swift`
- `Photix/Performance/LazyFilterGrid.swift`

#### Background Processing:
- `Photix/Processing/BackgroundProcessor.swift`

#### iOS 17+ Features:
- `Photix/iOS17Features/LiveActivity.swift`

#### Components & Utilities:
- `Photix/SwiftUI/Components/LoadingView.swift`
- `Photix/SwiftUI/Components/AsyncImageView.swift`
- `Photix/SwiftUI/Modifiers/ViewModifiers.swift`
- `Photix/SwiftUI/Bridge/ObjectiveCBridge.swift`
- `Photix/Accessibility/AccessibilitySupport.swift`

### 3. Framework Dependencies

Add these frameworks to your project:

#### Required Frameworks:
- `SwiftUI.framework`
- `Combine.framework`
- `ActivityKit.framework` (iOS 16.1+)
- `WidgetKit.framework`
- `Metal.framework`
- `MetalKit.framework`
- `AVFoundation.framework` (already included)
- `Photos.framework` (already included)
- `PhotosUI.framework` (already included)
- `CoreImage.framework` (already included)
- `StoreKit.framework` (already included)

### 4. Update Bridging Header

Update `Photix-Bridging-Header.h` to include:

```objective-c
//
//  Photix-Bridging-Header.h
//  Photix
//

#import "DNWAppDelegate.h"
#import "DNWMainViewController.h"
#import "DNWFilterViewController.h"
#import "DNWPictureViewController.h"
#import "DNWSettingsViewController.h"
#import "DNWFilterImage.h"
#import "DNWFilteredImageModel.h"
#import "DatabaseManager.h"
#import "IAPHelper.h"
#import "PhotixIAPHelper.h"
#import "Constants.h"
#import "UIImage+normalizedImage.h"
```

### 5. App Targets Configuration

#### Main App Target:
- Add SwiftUI as the main interface (optional - can gradually migrate)
- Keep existing Objective-C code for backward compatibility

#### Widget Extension (Optional):
Create a new widget extension target for iOS 17+ widgets

#### Live Activity Extension (Optional):
Create a notification content extension for Live Activities

### 6. Build Phases

Ensure these build phases are configured:

#### Compile Sources:
All Swift and Objective-C files should be included

#### Link Binary with Libraries:
All required frameworks should be linked

#### Copy Bundle Resources:
- Image assets
- Storyboards
- Launch screens

### 7. Migration Strategy

#### Option A: Gradual Migration (Recommended)
1. Keep existing Objective-C code as-is
2. Add new SwiftUI views alongside existing views
3. Use bridging classes to connect old and new code
4. Migrate view by view over time

#### Option B: Complete Replacement
1. Replace app delegate with SwiftUI app structure
2. Update storyboard references to point to SwiftUI views
3. Remove old view controllers gradually

### 8. Testing the Setup

After making these changes, test:

1. **Build Success**: Project should compile without errors
2. **SwiftUI Previews**: Should work in Xcode
3. **Mixed Code**: Objective-C and Swift should interoperate
4. **New Features**: Camera, filters, and modern UI should function
5. **Backward Compatibility**: Existing features should still work

### 9. Common Issues & Solutions

#### Issue: Swift files not found
**Solution**: Ensure all Swift files are added to the target membership

#### Issue: Bridging header not found
**Solution**: Check the bridging header path in build settings

#### Issue: Framework not found
**Solution**: Verify all frameworks are properly linked

#### Issue: Deployment target errors
**Solution**: Ensure all targets have iOS 16.0+ deployment target

#### Issue: SwiftUI previews not working
**Solution**: Enable previews in build settings and ensure simulator is iOS 16+

## Next Steps

1. Open project in Xcode 15+
2. Apply the settings changes above
3. Add all new Swift files to the project
4. Configure framework dependencies
5. Test build and run
6. Start using new SwiftUI features!

The modernized app will have:
- Modern SwiftUI interface
- Advanced camera with real-time filters
- Metal-accelerated rendering
- Live Activities and widgets
- Full accessibility support
- Background processing
- Enhanced photo management

All while maintaining compatibility with the existing Objective-C codebase.