//
//  TariffScreen.swift
//  tns-energo
//
//  Created by aristarh on 05.04.2025.
//

import SwiftUI
import Drawer
import UniformTypeIdentifiers

struct TariffScreen: View {
    
    @Shared(.currentTariff) var currentTariff: TariffCalculation?
    
    @ObservedObject var state: TariffState
    @FocusState private var isPowerFieldFocused: Bool
    
//    @State private var tariffPrice: String = "0.00 ₽/кВт"
//    @State private var tariffType: String = ""

    var body: some View {
        VStack {
            // Верхняя плашка (пример)
            VStack {
                if let price = currentTariff?.cost {
                    Text(NumberFormatter.twoFractionDigits().string(from: NSNumber(value: Float(price)!))!)
                        .font(.system(size: 32, weight: .black))
                } else {
                    Text("0.00 ₽/кВт")
                        .font(.system(size: 32, weight: .black))
                }
                Text("в среднем")
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 150)
            Spacer()
            infoSheet
        }
        .frame(maxHeight: .infinity)
        .background { Color.green.ignoresSafeArea(.all, edges: .top) }
        .onTapGesture {
            isPowerFieldFocused = false // Скрываем клавиатуру при тапе
        }
        .sheet(item: $state.destination.openChangeTariffSheet, id: \.self) { tariffs in
            state.changeTariffState(tariffs: tariffs).screen
                .presentationDetents([.height(370)])
        }
        .sheet(item: $state.destination.openHelpChoosingTariffSheet, id: \.self) { _ in
            state.tariffHelpState.screen
                .presentationDetents([.height(300)])
        }
        .fileImporter(
            isPresented: $state.isImporting,
            allowedContentTypes: [.data, .item, UTType(filenameExtension: "xlsx")!],
            allowsMultipleSelection: false // Предполагается загрузка одного файла
        ) { result in
            switch result {
            case .success(let urls):
                guard let selectedURL = urls.first else { return }
                Task {
                    do {
                        let localURL = try await copyFileToLocalCaches(url: selectedURL)
                        state.uploadedFiles = [localURL]
                        await state.uploadMultipleFiles()
                    } catch {
                        print("Ошибка копирования: \(error)")
                    }
                }
            case .failure(let error):
                print("Ошибка импорта: \(error)")
            }
        }
//        .onChange(of: state.$currentTariff) { value in
//            changeTariff(string)
//        }
    }
    
//    func changeTariff(_ value: String) {
//        guard let newTariff = state.calculatedTariffs.first(where: { $0.type == value }) else { return }
//        self.tariffType = newTariff.type
//        self.tariffPrice = newTariff.cost
//    }

    @ViewBuilder
    private var infoSheet: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Тип тарифа: ")
                        .bold()
                    Spacer()
                    Text(state.currentTariff?.type ?? "Не установлен")
                }
                if state.calculatedTariffs.isEmpty {
                    Spacer()
                    Text("Нет загруженных тарифов")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
//                    ForEach(state.calculatedTariffs) { tariff in
//                        VStack(alignment: .leading, spacing: 4) {
//                            HStack {
//                                Text("ЦК \(tariff.type)")
//                                    .bold()
//                                Spacer()
//                                Text(tariff.cost)
//                                    .bold()
//                            }
//                            if !tariff.isApplicable {
//                                Text("* Чтобы подключить, снизьте мощность на \(tariff.changeRecommendation) кВт")
//                                    .font(.caption)
//                                    .foregroundColor(.orange)
//                            }
//                        }
//                        .padding()
//                        .background(Color(.systemGray6))
//                        .clipShape(RoundedRectangle(cornerRadius: 16))
//                    }
                }
                //            switch state.currentTariff {
                //            case .singleZone(let zones),
                //                 .doubleZone(let zones),
                //                 .tripleZone(let zones):
                //                ForEach(zones, id: \.self) { zone in
                //                    HStack {
                //                        VStack(alignment: .leading) {
                //                            Text(zone.title)
                //                                .bold()
                //                            ForEach(zone.dates, id: \.self) { date in
                //                                Text("\(state.formatter.string(from: date.start)) - \(state.formatter.string(from: date.end))")
                //                            }
                //                        }
                //                        Spacer()
                //                        Text(zone.price.description)
                //                    }
                //                }
                //            }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Параметры перед загрузкой Excel")
                        .bold()
                    Picker("Категория напряжения", selection: $state.voltageCategory) {
                        Text("ВН").tag("BH")
                        Text("СН1").tag("CH1")
                        Text("СН11").tag("CH11")
                        Text("НН").tag("HH")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: state.voltageCategory) { _ in
                        state.resetTariffData()
                        state.maxPowerCapacity = ""
                    }
                    TextField("Максимальная мощность (кВт)", text: $state.maxPowerCapacity)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($isPowerFieldFocused)
                    
                    Text("Тип договора")
                    Picker("", selection: $state.contractType) {
                        Text("Купли-продажи").tag("true")
                        Text("Энергоснабжения").tag("false")
                    }
                    .pickerStyle(.segmented)
                }
                Button("Загрузить из Excel") {
                    isPowerFieldFocused = false
                    state.isImporting = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.green)
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 12))
            }
            .padding()
        }
        .frame(minHeight: 500, alignment: .top)
        .background(.white)
        .clipShape(.rect(topLeadingRadius: 24, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 24, style: .continuous))
    }
}

// MARK: - Вспомогательная функция копирования в локальный кэш
func copyFileToLocalCaches(url: URL) async throws -> URL {
    let fileManager = FileManager.default
    let cachesURL = try fileManager.url(
        for: .cachesDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    )
    let localURL = cachesURL.appendingPathComponent(url.lastPathComponent)

    if fileManager.fileExists(atPath: localURL.path) {
        try fileManager.removeItem(at: localURL)
    }

    guard url.startAccessingSecurityScopedResource() else {
        throw URLError(.noPermissionsToReadFile)
    }
    defer {
        url.stopAccessingSecurityScopedResource()
    }

    try fileManager.copyItem(at: url, to: localURL)
    return localURL
}


#Preview {
    ContentView()
}
