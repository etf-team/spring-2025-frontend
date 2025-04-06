//
//  CounterScreen.swift
//  tns-energo
//
//  Created by aristarh on 05.04.2025.
//

import SwiftUI

struct CounterScreen: View {
    
    @ObservedObject var state: CounterState
    
    var body: some View {
        VStack {
            Picker("asd", selection: $state.viewMode) {
                ForEach(CounterState.ViewMode.allCases) { mode in
                    Text(mode.rawValue)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            ScrollView(.vertical) {
                switch state.viewMode {
                case .sendData:
                    counterView
                case .viewHistory:
                    historyView
                }
            }
            .overlay(alignment: .bottom) {
                Group {
                    switch state.viewMode {
                    case .sendData:
                        Button("Передать") {
                            Task {
                                await state.sendMeterData()
                            }
                        }
                    case .viewHistory:
                        Button("Скачать в PDF") {
                            state.exportToPDF()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.green)
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 12))
            }
        }
        .padding()
        .navigationTitle(state.tabTitle)
        .refreshable {
            // Будет использоваться для обновления данных, если нужно
        }
        .fullScreenCover(item: $state.destination.openCamera, id: \.self) { _ in
            // Переход на экран камеры
        }
    }
    
    @ViewBuilder
    private var counterView: some View {
        LazyVStack(alignment: .leading, spacing: 12, pinnedViews: .sectionHeaders) {
            Section {
                VStack(alignment: .leading) {
                    Text("Предыдущие значения: ")
                        .bold()
                        .font(.system(size: 20))
                    Text("Пик: 112.0")
                    Text("Полупик: 112.0")
                    Text("Ночные: 112.0")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(cgColor: UIColor.systemGray6.cgColor))
                .clipShape(.rect(cornerRadius: 16))
                .opacity(0.8)
            } header: {
                HStack {
                    Text("Счётчик №000000")
                        .bold()
                        .font(.system(size: 26))
                    Spacer()
                    Button {
                        state.destination = .openCamera()
                    } label: {
                        Image(systemName: "camera.viewfinder")
                            .padding(6)
                            .background(.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .foregroundStyle(.white)
                }
                .padding(.vertical, 8)
                .background(.white)
            }
            
            Group {
                Text("Новые")
                    .bold()
                    .font(.system(size: 20))
                
                Group {
                    TextField("Пиковые значения", text: $state.peakValue)
                    TextField("Полупиковые значения", text: $state.halfPeakValue)
                    TextField("Ночные значения", text: $state.nightValue)
                }
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private var historyView: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section {
                ForEach(state.entries) { entry in
                    HStack {
                        Text("\(entry.peak)  \(entry.halfPeak)  \(entry.night)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(entry.date.formatted(date: .numeric, time: .omitted))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing)
                    }
                }
            } header: {
                Text("История")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(cgColor: UIColor.systemGray6.cgColor))
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
    }
}

#Preview {
    ContentView()
//    CounterScreen(state: CounterState())
}
