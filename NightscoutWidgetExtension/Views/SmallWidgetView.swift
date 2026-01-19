//
//  SmallWidgetView.swift
//  NightscoutWidgetExtension
//
//  Created on 19.01.2026.
//

import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: Entry?
    let bgUnits: String
    let error: String?
    
    var body: some View {
        if let error = error {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title)
                    .foregroundColor(.orange)
                Text(error)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
            }
            .padding()
        } else if let entry = entry {
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(bgValueString(entry: entry))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(bgColor(entry: entry))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text(entry.directionArrow)
                        .font(.system(size: 22))
                        .foregroundColor(bgColor(entry: entry))
                }
                
                Text(bgUnits == "mgdl" ? "mg/dL" : "mmol/L")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(entry.minutesAgo) min")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
                
                if entry.isStale {
                    Text("Veraltet")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .bold()
                }
            }
            .padding()
            .widgetURL(URL(string: "nightscout-widget://settings"))
        } else {
            VStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("Keine Daten")
                    .font(.caption)
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
