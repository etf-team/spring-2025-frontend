//
//  MainState.swift
//  ios-app
//
//  Created by aristarh on 25.10.2024.
//

import Foundation
import Dependencies
import Combine

// MARK: - State

@MainActor
final class MainState: ObservableObject {
    
    // MARK: - Screen
    
    var screen: MainScreen { MainScreen(state: self) }
    
    // MARK: - SubScreens
    
    private let counterState = CounterState()
    private let tariffState = TariffState()
    lazy var tabScreens: [any Tabbable] = [counterState, tariffState]
    
    // MARK: - Properties
    
    @Published var launched: Bool = false
    
    // MARK: - Init
    
    init() {}
}
