//
//  AppNavigation.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI
import Combine

enum NavigationDestination: Hashable {
    case filters
    case photoEdit
    case settings
}

class NavigationState: ObservableObject {
    @Published var path = NavigationPath()
    
    func navigateTo(_ destination: NavigationDestination) {
        path.append(destination)
    }
    
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func navigateToRoot() {
        path = NavigationPath()
    }
}