//
//  ChangeTariffState.swift
//  tns-energo
//
//  Created by aristarh on 05.04.2025.
//

import Foundation
import Sharing

//extension SharedKey where Self == AppStorageKey<TariffCalculation> {
//    
//    static var currentTariff: Self {
//        appStorage("currentTariff")
//    }
//}

final class ChangeTariffState: ObservableObject {
    
    // MARK: - Screen
    
    var screen: ChangeTariffSheet {
        ChangeTariffSheet(state: self)
    }
    
    // MARK: - Properties
    
    let tarrifs: [TariffCalculation]
    @Shared(.currentTariff) var currentTariff: TariffCalculation?
    
    // MARK: - Init
    
    init(tarrifs: [TariffCalculation]) {
        self.tarrifs = tarrifs
    }
    
    // MARK: - Methods
    
    func change(tariff: TariffCalculation) {
        self.$currentTariff.withLock { $0 = tariff }
    }
}
