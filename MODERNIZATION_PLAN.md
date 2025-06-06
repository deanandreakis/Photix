# Photix iOS App Modernization Plan

## Current Architecture Analysis

The app is a photo editing application with these key components:
- **Main flow**: Photo capture/selection → Filter application → Final editing/sharing
- **Core technologies**: UIKit, Core Data, StoreKit (IAP), Photos framework
- **Filter system**: Custom CIKernel implementation (already in Swift)
- **Navigation**: Storyboard-based with UINavigationController

## Migration Strategy

### Phase 1: Foundation & Swift Conversion (2-3 weeks)
1. **Convert Model Layer to Swift**
   - `DatabaseManager` → SwiftData/Core Data with Swift
   - `DNWFilteredImageModel` → Swift struct/class with Codable
   - Create Swift-based dependency injection container

2. **Modernize Image Processing**
   - Keep existing `KuwaharaFilter` (already Swift)
   - Convert `DNWFilterImage` to Swift with async/await
   - Implement `@Observable` models for filter state

### Phase 2: SwiftUI View Layer (3-4 weeks)
1. **Main Navigation Structure**
   ```swift
   ContentView (TabView/NavigationStack)
   ├── PhotoCaptureView (Camera + Photo Library)
   ├── FilterSelectionView (Horizontal ScrollView)
   └── EditingView (Final adjustments + Export)
   ```

2. **Key SwiftUI Views**
   - `PhotoCaptureView`: Replace `DNWMainViewController`
   - `FilterGridView`: Replace `DNWFilterViewController` 
   - `PhotoEditView`: Replace `DNWPictureViewController`
   - `SettingsView`: Replace `DNWSettingsViewController`

### Phase 3: Modern iOS Features (2-3 weeks)
1. **Enhanced Camera Integration**
   - AVFoundation camera with SwiftUI
   - Live photo support
   - Multiple photo selection

2. **Performance & UX**
   - SwiftUI lazy loading for filters
   - Metal shaders for real-time preview
   - Background processing with TaskGroup

## Proposed SwiftUI Architecture

```swift
// MARK: - App Structure
@main
struct PhotixApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(PhotoManager())
                .environmentObject(FilterManager())
        }
    }
}

// MARK: - Core Models
@Observable
class PhotoManager {
    var selectedImage: UIImage?
    var filteredImage: UIImage?
    var isProcessing = false
}

@Observable  
class FilterManager {
    var availableFilters: [FilterType] = []
    var selectedFilter: FilterType?
    
    func applyFilter(_ filter: FilterType, to image: UIImage) async -> UIImage?
}

// MARK: - Main Views
struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                PhotoCaptureView()
                    .tabItem { Label("Capture", systemImage: "camera") }
                    .tag(0)
                
                if photoManager.selectedImage != nil {
                    FilterSelectionView()
                        .tabItem { Label("Filters", systemImage: "camera.filters") }
                        .tag(1)
                }
            }
        }
    }
}
```

## Migration Benefits

**Immediate Wins:**
- Modern Swift concurrency (async/await) for image processing
- SwiftUI reactive UI updates
- Simplified state management with @Observable
- Better memory management

**Long-term Benefits:**
- iOS 17+ features (Live Activities, Widgets)
- Easier testing with SwiftUI previews
- Reduced code complexity (~40% less code)
- Better accessibility support

**Risk Mitigation:**
- Incremental migration preserves existing functionality
- Core filter algorithms remain unchanged
- Gradual rollout by feature area

## Timeline Estimate: 7-10 weeks total

This phased approach ensures minimal disruption while modernizing to current iOS development standards. The filter processing engine can be preserved and enhanced, while the UI layer gets completely rebuilt for better performance and maintainability.

## Detailed Migration Steps

### Phase 1 Tasks:
1. Create new Swift files for data models
2. Implement SwiftData schema or modernize Core Data stack
3. Convert `IAPHelper` to modern StoreKit 2
4. Set up async image processing pipeline
5. Create shared state management with @Observable

### Phase 2 Tasks:
1. Design SwiftUI component hierarchy
2. Implement photo capture with PhotosPicker
3. Build filter selection grid with lazy loading
4. Create editing interface with gesture controls
5. Add sharing and export functionality

### Phase 3 Tasks:
1. Integrate AVFoundation camera controls
2. Add real-time filter preview
3. Implement background processing
4. Add accessibility features
5. Performance optimization and testing

## File Migration Mapping

| Objective-C File | Swift/SwiftUI Replacement |
|------------------|----------------------------|
| `DNWMainViewController` | `PhotoCaptureView` |
| `DNWFilterViewController` | `FilterSelectionView` |
| `DNWPictureViewController` | `PhotoEditView` |
| `DNWSettingsViewController` | `SettingsView` |
| `DatabaseManager` | `DataManager` (SwiftData) |
| `IAPHelper` | `StoreManager` (StoreKit 2) |
| `DNWFilterImage` | `FilterProcessor` |
| `DNWFilteredImageModel` | `FilteredImage` struct |

## Technology Stack Upgrade

| Current | Modern Replacement |
|---------|-------------------|
| UIKit | SwiftUI |
| Core Data | SwiftData |
| StoreKit 1 | StoreKit 2 |
| UIImagePickerController | PhotosPicker |
| Delegate patterns | async/await + @Observable |
| Manual memory management | Automatic with ARC |
| Storyboards | SwiftUI declarative UI |