//
//  clientforfileserverApp.swift
//  clientforfileserver
//
//  Created by yafoxin on 30.06.2025.
//

import SwiftUI

@main
struct clientforfileserverApp: App {
    @StateObject private var store = ProfileStore()
    
    var body: some Scene {
        WindowGroup {
            TabsView()
                .environmentObject(store)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
