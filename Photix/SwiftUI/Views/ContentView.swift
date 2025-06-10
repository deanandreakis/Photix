//
//  ContentView.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var photoManager: PhotoManager
    @EnvironmentObject private var dependencies: DependencyContainer
    @StateObject private var navigationState = NavigationState()
    
    var body: some View {
        NavigationStack(path: $navigationState.path) {
            PhotoCaptureView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    destinationView(for: destination)
                }
                .environmentObject(navigationState)
        }
        .tint(.primary)
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .filters:
            FilterSelectionView()
                .environmentObject(navigationState)
        case .photoEdit:
            PhotoEditView()
                .environmentObject(navigationState)
                .environmentObject(dependencies)
        case .settings:
            SettingsView()
                .environmentObject(navigationState)
        }
    }
}