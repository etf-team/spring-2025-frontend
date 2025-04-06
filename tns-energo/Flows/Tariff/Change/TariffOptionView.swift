//
//  TariffOptionView.swift
//  tns-energo
//
//  Created by aristarh on 05.04.2025.
//

import SwiftUI

extension NumberFormatter {
    
    static func twoFractionDigits() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        return formatter
    }
}

struct TariffOptionView: View {
    
    let tariff: TariffCalculation
    @Binding var isSelected: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Button {
            withAnimation(.bouncy) {
                isSelected.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tariff.type)
                            .font(.headline)
                            .bold()
                            .multilineTextAlignment(.leading)
                        Text("Цена за месяц: " + NumberFormatter.twoFractionDigits().string(from: NSNumber(value: Float(tariff.cost)!))! + "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 24))
                }
                if !tariff.isApplicable {
                    Divider()
                    Text("Чтобы поспользоваться, вам необходимо изменить макс. мощность на \(tariff.changeRecommendation) кВт")
                        .multilineTextAlignment(.leading)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
}
