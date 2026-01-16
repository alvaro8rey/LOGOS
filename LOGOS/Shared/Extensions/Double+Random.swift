//
//  Double+Random.swift
//  Logos
//
//  Extensión para generación de números aleatorios con seed
//

import Foundation

extension Double {
    static func random(in range: ClosedRange<Double>, using generator: inout SeededRandomNumberGenerator) -> Double {
        let random = Double(generator.next()) / Double(UInt64.max)
        return range.lowerBound + (range.upperBound - range.lowerBound) * random
    }
}
