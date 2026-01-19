//
//  Entry.swift
//  NightscoutWidget
//
//  Created on 19.01.2026.
//

import Foundation

struct Entry: Identifiable, Codable {
    let id = UUID()
    var time: Date
    var bgMg: Int
    var bgMmol: Double
    var direction: String
    
    enum CodingKeys: String, CodingKey {
        case time = "dateString"
        case bgMg = "sgv"
        case direction
    }
    
    init(time: Date, bgMg: Int, bgMmol: Double, direction: String) {
        self.time = time
        self.bgMg = bgMg
        self.bgMmol = bgMmol
        self.direction = direction
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateString = try container.decode(String.self, forKey: .time)
        
        // Versuche verschiedene Datumsformate
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            self.time = date
        } else {
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                self.time = date
            } else {
                // Fallback zu Unix-Timestamp (Millisekunden)
                if let timestamp = Double(dateString) {
                    self.time = Date(timeIntervalSince1970: timestamp / 1000)
                } else {
                    self.time = Date()
                }
            }
        }
        
        // sgv kann als Int oder String kommen
        if let bgValue = try? container.decode(Int.self, forKey: .bgMg) {
            self.bgMg = bgValue
        } else if let bgString = try? container.decode(String.self, forKey: .bgMg),
                  let bgValue = Int(bgString) {
            self.bgMg = bgValue
        } else {
            self.bgMg = 0
        }
        
        self.bgMmol = Double(bgMg) / 18.018018
        self.direction = (try? container.decode(String.self, forKey: .direction)) ?? "NONE"
    }
    
    var directionArrow: String {
        switch direction {
        case "DoubleUp":
            return "↑↑"
        case "SingleUp":
            return "↑"
        case "FortyFiveUp":
            return "➚"
        case "Flat", "NONE":
            return "→"
        case "FortyFiveDown":
            return "➘"
        case "SingleDown":
            return "↓"
        case "DoubleDown":
            return "↓↓"
        default:
            return "→"
        }
    }
    
    var isStale: Bool {
        let minutesAgo = Date().timeIntervalSince(time) / 60
        return minutesAgo > 15
    }
    
    var minutesAgo: Int {
        return Int(Date().timeIntervalSince(time) / 60)
    }
}

final class EntriesStore: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var loopIOB: String = ""
    @Published var loopCOB: String = ""
    @Published var pumpReservoir: String = ""
    @Published var pumpBattery: String = ""
    
    func getLatest() -> Entry? {
        return entries.first
    }
}

struct BGData: Identifiable {
    let id = UUID()
    let time: Date
    let bg: Double
}
