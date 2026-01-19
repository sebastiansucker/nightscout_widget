//
//  MediumWidgetView.swift
//  NightscoutWidgetExtension
//
//  Created on 19.01.2026.
//

import SwiftUI
import WidgetKit
import Charts

struct MediumWidgetView: View {
    let entry: Entry?
    let entries: [Entry]
    let bgUnits: String
    let error: String?
    
    var body: some View {
        if let error = error {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title)
                    .foregroundColor(.orange)
                Text(error)
                    .font(.caption)
            }
            .padding()
        } else if let entry = entry {
            HStack(spacing: 16) {
                // Linke Seite: BG-Wert
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(bgValueString(entry: entry))
                            .font(.system(size: bgUnits == "mmol" ? 36 : 42, weight: .bold, design: .rounded))
                            .foregroundColor(bgColor(entry: entry))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        
                        Text(entry.directionArrow)
                            .font(.system(size: bgUnits == "mmol" ? 24 : 28))
                            .foregroundColor(bgColor(entry: entry))
                    }
                    
                    Text(bgUnits == "mgdl" ? "mg/dL" : "mmol/L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text("\(entry.minutesAgo) min")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    if entry.isStale {
                        Text("Veraltet")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .bold()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Rechte Seite: Chart
                if !entries.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        BGChartView(entries: entries, bgUnits: bgUnits)
                            .frame(height: 80)
                        
                        Text("Letzte 45 Min")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .widgetURL(URL(string: "nightscout-widget://settings"))
        } else {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title)
                    .foregroundColor(.secondary)
                Text("Keine Daten")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func bgValueString(entry: Entry) -> String {
        if bgUnits == "mmol" {
            return String(format: "%.1f", entry.bgMmol)
        } else {
            return "\(entry.bgMg)"
        }
    }
    
    private func bgColor(entry: Entry) -> Color {
        if entry.isStale {
            return .orange
        }
        
        let thresholds = NightscoutService.shared.getThresholds()
        let value = bgUnits == "mmol" ? entry.bgMmol : Double(entry.bgMg)
        let low = bgUnits == "mmol" ? thresholds.bgLowMmol : thresholds.bgLowMgdl
        let high = bgUnits == "mmol" ? thresholds.bgHighMmol : thresholds.bgHighMgdl
        
        if value < low {
            return .red
        } else if value > high {
            return .yellow
        } else {
            return .green
        }
    }
}

