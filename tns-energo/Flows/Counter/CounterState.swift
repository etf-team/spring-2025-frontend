//
//  CounterState.swift
//  tns-energo
//
//  Created by aristarh on 05.04.2025.
//
import SwiftUI
import SwiftUINavigation
import PDFKit

// MARK: - Модель записи

struct CounterEntry: Identifiable, Codable {
    let id = UUID()
    let peak: String
    let halfPeak: String
    let night: String
    let date: Date
}

// MARK: - Состояние экрана счётчика

final class CounterState: ObservableObject, Tabbable {
    
    @MainActor
    func sendMeterData() async {
        guard let url = URL(string: "https://etf-team.ru/api/clients/meter-data") else { return }

        let payload: [String: Any] = [
            "peak": peakValue,
            "half_peak": halfPeakValue,
            "night": nightValue,
            "date": ISO8601DateFormatter().string(from: Date())
        ]

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                print("Ошибка ответа от сервера")
                return
            }

            // Успешно — можно сохранить локально
            saveEntry()

        } catch {
            print("Ошибка отправки: \(error)")
        }
    }
    
    // MARK: - Tabbable
    
    let tabTitle: String = "Счётчик"
    let tabImage: String = "camera.viewfinder"
    var screen: AnyView { AnyView(CounterScreen(state: self)) }
    
    // MARK: - View Mode
    
    enum ViewMode: String, CaseIterable, Identifiable {
        var id: String { self.rawValue }
        case sendData = "Отправить"
        case viewHistory = "История"
    }
    
    // MARK: - Published свойства
    
    @Published var viewMode: ViewMode = .sendData
    @Published var peakValue: String = ""
    @Published var halfPeakValue: String = ""
    @Published var nightValue: String = ""
    @Published var entries: [CounterEntry] = []
    @Published var destination: Destination?

    // MARK: - Методы

    func saveEntry() {
        let entry = CounterEntry(
            peak: peakValue,
            halfPeak: halfPeakValue,
            night: nightValue,
            date: Date()
        )
        entries.insert(entry, at: 0)
        
        // Очистка полей
        peakValue = ""
        halfPeakValue = ""
        nightValue = ""
    }
    
    func exportToPDF() {
        let pdfMetaData = [
            kCGPDFContextCreator: "EnergyApp",
            kCGPDFContextAuthor: "ТНС Энерго",
            kCGPDFContextTitle: "История показаний"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 595.2
        let pageHeight = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let title = "История показаний"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24)
            ]
            title.draw(at: CGPoint(x: 20, y: 20), withAttributes: titleAttributes)
            
            var y = 60.0
            let spacing = 80.0
            
            for entry in entries {
                let date = DateFormatter.localizedString(from: entry.date, dateStyle: .short, timeStyle: .none)
                let block = """
                Дата: \(date)
                Пик: \(entry.peak)
                Полупик: \(entry.halfPeak)
                Ночь: \(entry.night)

                """
                let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14)]
                block.draw(at: CGPoint(x: 20, y: y), withAttributes: attrs)
                y += spacing
                
                if y > pageHeight - 100 {
                    context.beginPage()
                    y = 20
                }
            }
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("История_счетчика.pdf")
        
        do {
            try data.write(to: tempURL)
            presentShareSheet(with: tempURL)
        } catch {
            print("Ошибка при записи PDF: \(error)")
        }
    }

    private func presentShareSheet(with fileURL: URL) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        
        let vc = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        root.present(vc, animated: true)
    }

    // MARK: - Навигация
    
    @CasePathable
    enum Destination {
        case openCamera(String = "openCamera")
    }

    // MARK: - init
    
    init() {}
}
