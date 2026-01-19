//
//  LargeWidgetView.swift
//  NightscoutWidgetExtension
//
//  Created on 19.01.2026.
//

import SwiftUI
import WidgetKit
import Charts

struct LargeWidgetView: View {
    let entry: Entry?
    let entries: [Entry]
    let bgUnits: String
    let error: String?
    
    var body: some View {
        if let error = error {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text(error)
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
            .padding()
        } else if let entry = entry {
            VStack(spacing: 12) {
                // Oberer Bereich: BG-Wert und Info
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(bgValueString(entry: entry))
                                .font(.system(size: bgUnits == "mmol" ? 44 : 52, weight: .bold, design: .rounded))
                                .foregroundColor(bgColor(entry: entry))
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            
                            Text(entry.directionArrow)
                                .font(.system(size: bgUnits == "mmol" ? 30 : 36))
                                .foregroundColor(bgColor(entry: entry))
                        }
                        
                        Text(bgUnits == "mgdl" ? "mg/dL" : "mmol/L")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
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
                        
                        Text(dateString(entry.time))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Chart
                if !entries.isEmpty {
                    BGChartView(entries: entries, bgUnits: bgUnits)
                        .frame(height: 100)
                }
            }
            .padding()
            .widgetURL(URL(string: "nightscout-widget://settings"))
        } else {
            VStack(spacing: 16) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.largeTitle)
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
    
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
