//
//  OpenSettingsIntent.swift
//  NightscoutWidgetExtension
//
//  Created on 19.01.2026.
//

import AppIntents
import Foundation

struct OpenSettingsIntent: AppIntent {
    static var title: LocalizedStringResource = "Einstellungen öffnen"
    static var description = IntentDescription("Öffnet die Nightscout-Einstellungen")
    
    func perform() async throws -> some IntentResult {
        // Öffne die Hauptapp
        if let url = URL(string: "nightscout-widget://settings") {
            await NSWorkspace.shared.open(url)
        }
        return .result()
    }
}

struct ReloadWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Widget aktualisieren"
    static var description = IntentDescription("Lädt die Widget-Daten neu")
    
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
