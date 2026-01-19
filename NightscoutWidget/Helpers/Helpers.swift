//
//  Helpers.swift
//  NightscoutWidget
//
//  Created on 19.01.2026.
//

import Foundation

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

func convertBgMgToMmol(_ bgMg: Int) -> Double {
    let bgMmol = (Double(bgMg) / 18.018018 * 10).rounded() / 10
    return bgMmol
}
