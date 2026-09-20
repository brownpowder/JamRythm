//
//  ContentView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import SwiftUI


struct ContentView: View {
    @StateObject private var tourManager = TourManager.shared
    @StateObject private var storeManager = StoreManager.shared
    var body: some View {
        ZStack {
            ProjectListView()
            
            // TourOverlayView(spaceName: "TourSpace")
        }
        // No longer using PreferenceKey, modifier writes to TourManager directly
        .environmentObject(tourManager)
    }
}

#Preview {
    ContentView()
}
 
