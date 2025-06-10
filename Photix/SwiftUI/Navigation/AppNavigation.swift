//
//  AppNavigation.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI
import Combine

enum NavigationDestination: Hashable, CaseIterable {
    case filters
    case photoEdit
    case settings
}

class NavigationState: ObservableObject {
    @Published var path: [NavigationDestination] = []
    
    func navigateTo(_ destination: NavigationDestination) {
        print("NavigationState: Navigating to \(destination)")
        print("NavigationState: Current path count: \(path.count)")
        path.append(destination)
        print("NavigationState: New path count: \(path.count)")
        print("NavigationState: Path contents: \(path)")
    }
    
    func navigateBack() {
        print("NavigationState: Navigating back")
        if !path.isEmpty {
            path.removeLast()
        }
        print("NavigationState: Path count after back: \(path.count)")
    }
    
    func navigateToRoot() {
        print("NavigationState: Navigating to root")
        path = []
        print("NavigationState: Path cleared")
    }
}