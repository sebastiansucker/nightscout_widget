//
//  NightscoutWidgetExtension.swift
//  NightscoutWidgetExtension
//
//  Created on 19.01.2026.
//

import WidgetKit
import SwiftUI

// Alias um Namenskonflikt mit TimelineProvider.Entry zu vermeiden
typealias GlucoseEntry = Entry

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        let placeholderEntry = GlucoseEntry(
            time: Date(),
            bgMg: 120,
            bgMmol: 6.7,
            direction: "Flat"
        )
        
        return SimpleEntry(
            date: Date(),
            entry: placeholderEntry,
            entries: [],
            loopProperties: LoopProperties(),
            error: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task {
            let entry = await fetchWidgetData()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        Task {
            let currentEntry = await fetchWidgetData()
            
            // Aktualisiere jede Minute
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
            let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
    
    private func fetchWidgetData() async -> SimpleEntry {
        let service = NightscoutService.shared
        
        print("[Widget] Starte Datenabruf...")
        
        do {
            let entries = try await service.fetchEntries()
            
            print("[Widget] Empfangen: \(entries.count) Einträge")
            
            guard let latestEntry = entries.first else {
                print("[Widget] Keine Einträge in der Antwort")
                return SimpleEntry(
                    date: Date(),
                    entry: nil,
                    entries: [],
                    loopProperties: LoopProperties(),
                    error: "Keine Daten vom Server"
                )
            }
            
            // Hole Loop-Daten wenn aktiviert
            let userDefaults = UserDefaults(suiteName: "group.com.nightscout.widget")
            let showLoopData = userDefaults?.bool(forKey: "showLoopData") ?? false
            
            var loopProperties = LoopProperties()
            if showLoopData {
                do {
                    loopProperties = try await service.fetchProperties()
                } catch {
                    print("Loop-Daten konnten nicht geladen werden: \(error)")
                }
            }
            
            print("[Widget] Erfolg: Aktueller BG = \(latestEntry.bgMg) mg/dL")
            
            return SimpleEntry(
                date: Date(),
                entry: latestEntry,
                entries: Array(entries.prefix(60)),
                loopProperties: loopProperties,
                error: nil
            )
            
        } catch {
            print("[Widget] Fehler: \(error)")
            return SimpleEntry(
                date: Date(),
                entry: nil,
                entries: [],
                loopProperties: LoopProperties(),
                error: "Fehler: \(error.localizedDescription)"
            )
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let entry: GlucoseEntry?
    let entries: [GlucoseEntry]
    let loopProperties: LoopProperties
    let error: String?
}

struct NightscoutWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    @AppStorage("bgUnits", store: UserDefaults(suiteName: "group.com.nightscout.widget"))
    private var bgUnits = "mgdl"
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry.entry, bgUnits: bgUnits, error: entry.error)
            case .systemMedium:
                MediumWidgetView(entry: entry.entry, entries: entry.entries, bgUnits: bgUnits, error: entry.error)
            case .systemLarge:
                LargeWidgetView(
                    entry: entry.entry,
                    entries: entry.entries,
                    bgUnits: bgUnits,
                    error: entry.error
                )
            default:
                SmallWidgetView(entry: entry.entry, bgUnits: bgUnits, error: entry.error)
            }
        }
        .widgetURL(URL(string: "nightscout-widget://"))
    }
}

@main
struct NightscoutWidget: Widget {
    let kind: String = "NightscoutWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NightscoutWidgetEntryView(entry: entry)
                .containerBackground(Color(white: 0.4), for: .widget)
        }
        .configurationDisplayName("Nightscout")
        .description("Zeigt deine aktuellen Glukose-Werte von Nightscout an")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    NightscoutWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        entry: GlucoseEntry(time: Date(), bgMg: 120, bgMmol: 6.7, direction: "Flat"),
        entries: [],
        loopProperties: LoopProperties(),
        error: nil
    )
}
