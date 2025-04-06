//
//  TariffState.swift
//  tns-energo
//
//  Created by aristarh on 05.04.2025.
//

import SwiftUI
import Dependencies
import SwiftUINavigation
import UniformTypeIdentifiers
import Sharing
import Combine

// MARK: - Модель ответа от API
struct TariffResponse: Decodable {
    struct Category: Decodable {
        struct Applicability: Decodable {
            let is_applicable_power_capacity: Bool
            let power_capacity_change_recommendation: Int
        }
        let applicability: Applicability
        let category_type: String
        let total_cost: String
    }
    let categories: [Category]
}

// MARK: - UI-модель тарифа
struct TariffCalculation: Identifiable, Hashable, Codable {
    let id = UUID()
    let type: String
    let cost: String
    let isApplicable: Bool
    let changeRecommendation: Int
}

enum Tariff: Hashable, CaseIterable {
    static var allCases: [Tariff] = [.singleZone(), .doubleZone(), .tripleZone()]
    
    enum Zone {
        case allDay, day, peak, halfPeak, night
        
        var title: String {
            switch self {
            case .allDay: return "Весь день"
            case .day: return "Дневная зона"
            case .peak: return "Пиковая зона"
            case .halfPeak: return "Полупиковая зона"
            case .night: return "Ночная зона"
            }
        }
        
        var price: Double {
            switch self {
            case .allDay: return 4.81
            case .day: return 5.54
            case .peak: return 6.27
            case .halfPeak: return 4.81
            case .night: return 2.89
            }
        }
        
        var dates: [DateInterval] {
            switch self {
            case .allDay:
                return [DateInterval(start: today(hour: 0), end: today(hour: 23))]
            case .day:
                return [DateInterval(start: today(hour: 7), end: today(hour: 23))]
            case .peak:
                return [
                    DateInterval(start: today(hour: 7), end: today(hour: 10)),
                    DateInterval(start: today(hour: 17), end: today(hour: 21))
                ]
            case .halfPeak:
                return [
                    DateInterval(start: today(hour: 10), end: today(hour: 17)),
                    DateInterval(start: today(hour: 21), end: today(hour: 23))
                ]
            case .night:
                var end = Calendar.current.date(byAdding: .day, value: 1, to: today(hour: 23)) ?? Date()
                end = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: end) ?? end
                return [DateInterval(start: today(hour: 23), end: end)]
            }
        }
        
        private func today(hour: Int) -> Date {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comps.hour = hour
            comps.minute = 0
            return Calendar.current.date(from: comps) ?? Date()
        }
    }
    
    case singleZone([Zone] = [.allDay])
    case doubleZone([Zone] = [.day, .night])
    case tripleZone([Zone] = [.peak, .halfPeak, .night])
    
    var midPrice: Double {
        switch self {
        case .singleZone(let zones), .doubleZone(let zones), .tripleZone(let zones):
            return arithmeticMean(of: zones.map { $0.price }) ?? 0.0
        }
    }
    
    var title: String {
        switch self {
        case .singleZone: return "Одноставочный тариф"
        case .doubleZone: return "Одноставочный тариф, по 2 зонам суток"
        case .tripleZone: return "Одноставочный тариф, по 3 зонам суток"
        }
    }
}

func arithmeticMean(of numbers: [Double]) -> Double? {
    guard !numbers.isEmpty else { return nil }
    return numbers.reduce(0, +) / Double(numbers.count)
}

extension DateFormatter {
    static func twoHoursTwoMinutes() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }
}

extension SharedKey where Self == FileStorageKey<TariffCalculation?> {
    
    static var currentTariff: Self {
        fileStorage(.documentsDirectory.appending(component: "currentTariff"))
    }
}

final class TariffState: ObservableObject, Tabbable {
    let tabTitle: String = "Тариф"
    let tabImage: String = "doc.text.magnifyingglass"
    var screen: AnyView { AnyView(TariffScreen(state: self)) }
    
//    var currentTariff: Tariff = .tripleZone()
    
    let formatter = DateFormatter.twoHoursTwoMinutes()
    
//    let changeTariffState = ChangeTariffState()
    func changeTariffState(tariffs: [TariffCalculation]) -> ChangeTariffState {
        ChangeTariffState(tarrifs: tariffs)
    }
    let tariffHelpState = TariffHelpState()
    
    @Published var destination: Destination?
    @Published var calculatedTariffs: [TariffCalculation] = []
    @Published var isImporting: Bool = false
    @Published var uploadedFiles: [URL] = []
    
    // Параметры, обязательные для запроса
    @Published var voltageCategory: String = "BH"
    @Published var maxPowerCapacity: String = ""
    @Published var contractType: String = "true"
    
    @CasePathable
    enum Destination {
        case openChangeTariffSheet([TariffCalculation])
        case openHelpChoosingTariffSheet(String = "openHelpChoosingTariffSheet")
    }
    
//    @Shared(.currentTariff) var currentTariff: TariffCalculation?
    
    private var bag = Set<AnyCancellable>()
    
    // Обновление категории и сброс старых данных
    func resetTariffData() {
        self.calculatedTariffs.removeAll()
        // Можно сбросить и другие значения, если требуется
    }
    
    @MainActor
    func uploadMultipleFiles() async {
        // Сбросить старые данные перед загрузкой
        resetTariffData()
        
        guard let maxPower = Double(maxPowerCapacity), !voltageCategory.isEmpty else {
            print("Ошибка: Введите корректную мощность и категорию напряжения")
            return
        }
        
        for url in uploadedFiles {
            do {
                let responses = try await uploadExcelFile(
                    fileUrl: url,
                    maxPower: maxPower,
                    voltageCategory: voltageCategory,
                    contractType: contractType
                )
                
                let mapped = responses.flatMap { response in
                    response.categories.map {
                        TariffCalculation(
                            type: $0.category_type,
                            cost: $0.total_cost,
                            isApplicable: $0.applicability.is_applicable_power_capacity,
                            changeRecommendation: $0.applicability.power_capacity_change_recommendation
                        )
                    }
                }
                
//                calculatedTariffs.append(contentsOf: mapped)
                calculatedTariffs = mapped
//                print("calculatedTariffs: \(calculatedTariffs)")
                destination = .openChangeTariffSheet(mapped)
                
            } catch {
                print("Ошибка при загрузке файла \(url.lastPathComponent): \(error)")
            }
        }
    }
}

func uploadExcelFile(
    fileUrl: URL,
    maxPower: Double,
    voltageCategory: String,
    contractType: String
) async throws -> [TariffResponse] {
    let boundary = UUID().uuidString
    let urlString = "https://etf-team.ru/api/clients/cases"
    
    guard var components = URLComponents(string: urlString) else {
        throw URLError(.badURL)
    }
    
    // Передаём обязательные параметры в query string
    components.queryItems = [
        URLQueryItem(name: "is_transmission_included", value: contractType),
        URLQueryItem(name: "max_power_capacity_kwt", value: String(maxPower)),
        URLQueryItem(name: "voltage_category", value: voltageCategory)
    ]
    
    guard let url = components.url else {
        throw URLError(.badURL)
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    var data = Data()
    data.append("--\(boundary)\r\n")
    data.append("Content-Disposition: form-data; name=\"payload\"; filename=\"file.xlsx\"\r\n")
    data.append("Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet\r\n\r\n")
    data.append(try Data(contentsOf: fileUrl))
    data.append("\r\n--\(boundary)--\r\n")
    
    let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)
    
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
        throw URLError(.badServerResponse)
    }
    
    let decodedResponse = try JSONDecoder().decode(TariffResponse.self, from: responseData)
    return [decodedResponse]
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}


