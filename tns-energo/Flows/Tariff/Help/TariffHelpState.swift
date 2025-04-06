//
//  TariffHelpState.swift
//  tns-energo
//
//  Created by aristarh on 05.04.2025.
//

import Foundation

final class TariffHelpState: ObservableObject {
    
    // MARK: - Screen
    
    var screen: TariffHelpScreen {
        TariffHelpScreen(state: self)
    }
    
    // MARK: - Init
    
    init() {}
}
