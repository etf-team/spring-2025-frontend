//
//  ChangeTariffSheet.swift
//  tns-energo
//
//  Created by aristarh on 05.04.2025.
//

import SwiftUI

struct ChangeTariffSheet: View {
    
    @ObservedObject var state: ChangeTariffState
    @State private var firstIsSelected: Bool = false
    @State private var secondIsSelected: Bool = false
    @State private var thirdIsSelected: Bool = false
    @State private var selectedTariff: TariffCalculation?
    
    var body: some View {
        VStack {
            ForEach(Array(state.tarrifs.enumerated()), id: \.offset) { index, tariff in
                switch index {
                case 0:
                    TariffOptionView(tariff: tariff, isSelected: $firstIsSelected)
                case 1:
                    TariffOptionView(tariff: tariff, isSelected: $secondIsSelected)
                default:
                    TariffOptionView(tariff: tariff, isSelected: $thirdIsSelected)
                }
            }
            Button("Сменить тариф") {
                if let selectedTariff {
                    state.change(tariff: selectedTariff)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.green)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 12))
        }
        .padding()
        .onChange(of: firstIsSelected) { value in
            if value {
                secondIsSelected = false
                thirdIsSelected = false
            }
        }
        .onChange(of: secondIsSelected) { value in
            if value {
                firstIsSelected = false
                thirdIsSelected = false
            }
        }
        .onChange(of: thirdIsSelected) { value in
            if value {
                firstIsSelected = false
                secondIsSelected = false
            }
        }
        .onAppear {
//            if let currentTariff = state.currentTariff {
//                for index in state.tarrifs.indices {
//                    if state.tarrifs[index].type == currentTariff {
//                        switch index {
//                        case 0:
//                            firstIsSelected = true
//                        case 1:
//                            secondIsSelected = true
//                        default:
//                            thirdIsSelected = true
//                        }
//                    }
//                }
//            }
        }
    }
}

#Preview {
    ContentView()
}
