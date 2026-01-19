//
//  NightscoutService.swift
//  NightscoutWidget
//
//  Created on 19.01.2026.
//

import Foundation
import WidgetKit

class NightscoutService {
    static let shared = NightscoutService()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.nightscout.widget")
    
    private var nightscoutUrl: String {
        userDefaults?.string(forKey: "nightscoutUrl") ?? ""
    }
    
    private var accessToken: String {
        userDefaults?.string(forKey: "accessToken") ?? ""
    }
    
    func fetchEntries() async throws -> [Entry] {
        guard !nightscoutUrl.isEmpty else {
            throw NightscoutError.noUrlConfigured
        }
        
        var urlString = nightscoutUrl
        if !accessToken.isEmpty {
            urlString += "/api/v1/entries.json?count=60&token=" + accessToken
        } else {
            urlString += "/api/v1/entries.json?count=60"
        }
        
        guard let url = URL(string: urlString) else {
            throw NightscoutError.invalidUrl
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NightscoutError.serverError
        }
        
        // Debug: Drucke die rohen Daten
        if let jsonString = String(data: data, encoding: .utf8) {
            print("JSON Response: \(jsonString.prefix(500))")
        }
        
        do {
            let entries = try JSONDecoder().decode([Entry].self, from: data)
            return entries.sorted { $0.time > $1.time }
        } catch {
            print("Decoding error: \(error)")
            throw error
        }
    }
    
    func fetchProperties() async throws -> LoopProperties {
        guard !nightscoutUrl.isEmpty else {
            throw NightscoutError.noUrlConfigured
        }
        
        var urlString = nightscoutUrl
        if !accessToken.isEmpty {
            urlString += "/api/v2/properties?token=" + accessToken
        } else {
            urlString += "/api/v2/properties"
        }
        
        guard let url = URL(string: urlString) else {
            throw NightscoutError.invalidUrl
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NightscoutError.serverError
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        var properties = LoopProperties()
        
        // Parse IOB
        if let iob = json?["iob"] as? [String: Any],
           let iobDisplay = iob["display"] as? String {
            properties.iob = iobDisplay
        }
        
        // Parse COB
        if let cob = json?["cob"] as? [String: Any],
           let cobDisplay = cob["display"] as? String {
            properties.cob = cobDisplay
        }
        
        // Parse Pump data
        if let pump = json?["pump"] as? [String: Any],
           let pumpData = pump["data"] as? [String: Any] {
            
            if let reservoir = pumpData["reservoir"] as? [String: Any],
               let reservoirDisplay = reservoir["display"] as? String {
                properties.pumpReservoir = reservoirDisplay
            }
            
            if let battery = pumpData["battery"] as? [String: Any],
               let batteryDisplay = battery["display"] as? String {
                properties.pumpBattery = batteryDisplay
            }
        }
        
        return properties
    }
    
    func fetchThresholds() async throws -> BGThresholds {
        guard !nightscoutUrl.isEmpty else {
            throw NightscoutError.noUrlConfigured
        }
        
        var urlString = nightscoutUrl
        if !accessToken.isEmpty {
            urlString += "/api/v1/status.json?token=" + accessToken
        } else {
            urlString += "/api/v1/status.json"
        }
        
        guard let url = URL(string: urlString) else {
            throw NightscoutError.invalidUrl
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NightscoutError.serverError
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        var thresholds = BGThresholds.default
        
        if let settings = json?["settings"] as? [String: Any],
           let thresholdsData = settings["thresholds"] as? [String: Any] {
            
            if let bgLow = thresholdsData["bgLow"] as? Double {
                thresholds.bgLowMgdl = bgLow
                thresholds.bgLowMmol = bgLow / 18.018018
            }
            
            if let bgHigh = thresholdsData["bgHigh"] as? Double {
                thresholds.bgHighMgdl = bgHigh
                thresholds.bgHighMmol = bgHigh / 18.018018
            }
        }
        
        // Schwellenwerte in UserDefaults speichern
        if let encoded = try? JSONEncoder().encode(thresholds) {
            userDefaults?.set(encoded, forKey: "bgThresholds")
        }
        
        return thresholds
    }
    
    func getThresholds() -> BGThresholds {
        guard let data = userDefaults?.data(forKey: "bgThresholds"),
              let thresholds = try? JSONDecoder().decode(BGThresholds.self, from: data) else {
            return BGThresholds.default
        }
        return thresholds
    }
}

struct LoopProperties {
    var iob: String = ""
    var cob: String = ""
    var pumpReservoir: String = ""
    var pumpBattery: String = ""
}

struct BGThresholds: Codable {
    var bgLowMgdl: Double
    var bgHighMgdl: Double
    var bgLowMmol: Double
    var bgHighMmol: Double
    
    static var `default`: BGThresholds {
        BGThresholds(
            bgLowMgdl: 70,
            bgHighMgdl: 180,
            bgLowMmol: 3.9,
            bgHighMmol: 10.0
        )
    }
}

enum NightscoutError: LocalizedError {
    case noUrlConfigured
    case invalidUrl
    case serverError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .noUrlConfigured:
            return "Keine Nightscout URL konfiguriert"
        case .invalidUrl:
            return "Ungültige URL"
        case .serverError:
            return "Server-Fehler"
        case .noData:
            return "Keine Daten"
        }
    }
}
