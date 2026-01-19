//
//  BGChartView.swift
//  NightscoutWidgetExtension
//
//  Created on 19.01.2026.
//

import SwiftUI
import Charts

struct BGChartView: View {
    let entries: [Entry]
    let bgUnits: String
    
    var recentEntries: [Entry] {
        let fortyFiveMinutesAgo = Date().addingTimeInterval(-45 * 60)
        return entries.filter { $0.time > fortyFiveMinutesAgo }
    }
    
    var yAxisRange: ClosedRange<Double> {
        guard !recentEntries.isEmpty else {
            return bgUnits == "mmol" ? 3.0...12.0 : 50.0...220.0
        }
        
        let values = recentEntries.map { bgUnits == "mmol" ? $0.bgMmol : Double($0.bgMg) }
        let minVal = values.min() ?? 0
        let maxVal = values.max() ?? 0
        
        let padding = bgUnits == "mmol" ? 1.0 : 20.0
        return (minVal - padding)...(maxVal + padding)
    }
    
    var body: some View {
        Chart {
            ForEach(recentEntries) { entry in
                LineMark(
                    x: .value("Zeit", entry.time),
                    y: .value("BG", bgUnits == "mmol" ? entry.bgMmol : Double(entry.bgMg))
                )
                .foregroundStyle(lineColor(for: entry))
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                PointMark(
                    x: .value("Zeit", entry.time),
                    y: .value("BG", bgUnits == "mmol" ? entry.bgMmol : Double(entry.bgMg))
                )
                .foregroundStyle(lineColor(for: entry))
                .symbolSize(30)
            }
            
            // Zielbereich-Markierung
            RuleMark(
                y: .value("Low", bgUnits == "mmol" ? 3.9 : 70)
            )
            .foregroundStyle(.red.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            
            RuleMark(
                y: .value("High", bgUnits == "mmol" ? 10.0 : 180)
            )
            .foregroundStyle(.yellow.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .minute, count: 15)) { _ in
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                if let intValue = value.as(Int.self) {
                    AxisValueLabel {
                        Text("\(intValue)")
                            .font(.caption2)
                    }
                } else if let doubleValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text(String(format: "%.1f", doubleValue))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYScale(domain: yAxisRange)
        .chartXScale(domain: Date().addingTimeInterval(-45 * 60)...Date())
    }
    
    private func lineColor(for entry: Entry) -> Color {
        let value = bgUnits == "mmol" ? entry.bgMmol : Double(entry.bgMg)
        let low = bgUnits == "mmol" ? 3.9 : 70.0
        let high = bgUnits == "mmol" ? 10.0 : 180.0
        
        if value < low {
            return .red
        } else if value > high {
            return .yellow
        } else {
            return .green
        }
    }
}
