//
//  TariffHelpScreen.swift
//  tns-energo
//
//  Created by aristarh on 05.04.2025.
//

import SwiftUI

struct TariffHelpScreen: View {
    
    @ObservedObject var state: TariffHelpState
    
    var body: some View {
        VStack {
            Button("Загрузить из Excel") {
                //
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.green)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 12))
            Button("Из локальной истории") {
                //
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.green)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 12))
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
