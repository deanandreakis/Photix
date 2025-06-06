//
//  PhotixApp.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI

struct PhotixApp: App {
    @StateObject private var dependencies = DependencyContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dependencies)
                .environmentObject(dependencies.photoManager)
                .environmentObject(dependencies.storeManager)
                .onAppear {
                    dependencies.configure()
                }
        }
    }
}