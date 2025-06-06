//
//  LiveActivity.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Live Activity Attributes

@available(iOS 16.1, *)
struct FilterProcessingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentStep: String
        var progress: Double
        var filterCount: Int
        var completedFilters: Int
        var estimatedTimeRemaining: TimeInterval
    }
    
    var sessionId: String
    var imageName: String
}

// MARK: - Live Activity Manager

@available(iOS 16.1, *)
@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var currentActivity: Activity<FilterProcessingAttributes>?
    @Published var isActivityActive = false
    
    private init() {}
    
    func startFilterProcessingActivity(
        sessionId: String,
        imageName: String,
        filterCount: Int
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not enabled")
            return
        }
        
        let attributes = FilterProcessingAttributes(
            sessionId: sessionId,
            imageName: imageName
        )
        
        let initialState = FilterProcessingAttributes.ContentState(
            currentStep: "Starting filter processing...",
            progress: 0.0,
            filterCount: filterCount,
            completedFilters: 0,
            estimatedTimeRemaining: Double(filterCount) * 0.5
        )
        
        do {
            let activity = try Activity<FilterProcessingAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            
            currentActivity = activity
            isActivityActive = true
            
            print("Live Activity started: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func updateProgress(
        currentStep: String,
        progress: Double,
        completedFilters: Int,
        estimatedTimeRemaining: TimeInterval
    ) async {
        guard let activity = currentActivity else { return }
        
        let updatedState = FilterProcessingAttributes.ContentState(
            currentStep: currentStep,
            progress: progress,
            filterCount: activity.attributes.imageName.count, // This would be properly tracked
            completedFilters: completedFilters,
            estimatedTimeRemaining: estimatedTimeRemaining
        )
        
        let content = ActivityContent(state: updatedState, staleDate: nil)
        
        do {
            await activity.update(content)
        } catch {
            print("Failed to update Live Activity: \(error)")
        }
    }
    
    func endActivity() async {
        guard let activity = currentActivity else { return }
        
        let finalState = FilterProcessingAttributes.ContentState(
            currentStep: "Processing complete!",
            progress: 1.0,
            filterCount: 0,
            completedFilters: 0,
            estimatedTimeRemaining: 0
        )
        
        let finalContent = ActivityContent(
            state: finalState,
            staleDate: Date().addingTimeInterval(5)
        )
        
        do {
            await activity.end(finalContent, dismissalPolicy: .after(.now + 3))
            currentActivity = nil
            isActivityActive = false
        } catch {
            print("Failed to end Live Activity: \(error)")
        }
    }
}

// MARK: - Live Activity Widget

@available(iOS 16.1, *)
struct FilterProcessingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FilterProcessingAttributes.self) { context in
            // Lock screen/banner UI
            FilterProcessingLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "camera.filters")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.completedFilters)/\(context.state.filterCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        Text(context.state.currentStep)
                            .font(.caption)
                            .lineLimit(1)
                        
                        ProgressView(value: context.state.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    }
                }
            } compactLeading: {
                Image(systemName: "camera.filters")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text("\(Int(context.state.progress * 100))%")
                    .font(.caption2)
                    .fontWeight(.semibold)
            } minimal: {
                Image(systemName: "camera.filters")
                    .foregroundColor(.blue)
            }
        }
    }
}

@available(iOS 16.1, *)
struct FilterProcessingLiveActivityView: View {
    let context: ActivityViewContext<FilterProcessingAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "camera.filters")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Photix - Filter Processing")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(context.attributes.imageName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(context.state.completedFilters)/\(context.state.filterCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    if context.state.estimatedTimeRemaining > 0 {
                        Text("\(Int(context.state.estimatedTimeRemaining))s left")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            VStack(spacing: 4) {
                HStack {
                    Text(context.state.currentStep)
                        .font(.caption)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
                
                ProgressView(value: context.state.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Widget Integration

@available(iOS 17.0, *)
struct PhotixWidget: Widget {
    let kind: String = "PhotixWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PhotixTimelineProvider()) { entry in
            PhotixWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Photix Quick Actions")
        .description("Quick access to camera and recent photos")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@available(iOS 17.0, *)
struct PhotixTimelineEntry: TimelineEntry {
    let date: Date
    let recentPhotoCount: Int
}

@available(iOS 17.0, *)
struct PhotixTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PhotixTimelineEntry {
        PhotixTimelineEntry(date: Date(), recentPhotoCount: 0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (PhotixTimelineEntry) -> Void) {
        let entry = PhotixTimelineEntry(date: Date(), recentPhotoCount: 5)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<PhotixTimelineEntry>) -> Void) {
        let entry = PhotixTimelineEntry(date: Date(), recentPhotoCount: 5)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

@available(iOS 17.0, *)
struct PhotixWidgetView: View {
    var entry: PhotixTimelineProvider.Entry
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "camera.filters")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Photix")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                // Camera shortcut
                Button(intent: OpenCameraIntent()) {
                    VStack(spacing: 4) {
                        Image(systemName: "camera")
                            .font(.title3)
                        Text("Camera")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                
                // Photo library shortcut
                Button(intent: OpenLibraryIntent()) {
                    VStack(spacing: 4) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title3)
                        Text("Library")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            
            if entry.recentPhotoCount > 0 {
                Text("\(entry.recentPhotoCount) recent photos")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
    }
}

// MARK: - App Intents for Widget

@available(iOS 16.0, *)
struct OpenCameraIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Camera"
    static var description = IntentDescription("Opens the camera to take a new photo")
    
    func perform() async throws -> some IntentResult {
        // This would need to be implemented to open the app to camera
        return .result()
    }
}

@available(iOS 16.0, *)
struct OpenLibraryIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Photo Library"
    static var description = IntentDescription("Opens the photo library to select images")
    
    func perform() async throws -> some IntentResult {
        // This would need to be implemented to open the app to library
        return .result()
    }
}