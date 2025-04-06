//
//  MainScreen.swift
//  ios-app
//
//  Created by aristarh on 25.10.2024.
//

import SwiftUI

// MARK: - Screen

struct MainScreen: View {
    
    // MARK: - Properties
    
    @StateObject var state: MainState
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if state.launched {
                TabView {
                    ForEach(state.tabScreens, id: \.id) { tabScreen in
                        NavigationStack {
                            tabScreen.screen
                                .navigationTitle(tabScreen.tabTitle)
                        }
                        .tabItem { Label(tabScreen.tabTitle, systemImage: tabScreen.tabImage) }
                    }
                }
            } else {
                LaunchScreen(launched: $state.launched)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainScreen(state: MainState())
}
