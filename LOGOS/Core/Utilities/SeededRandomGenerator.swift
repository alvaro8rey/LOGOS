//
//  SeededRandomGenerator.swift
//  LOGOS
//
//  Generador de números aleatorios con semilla para puzzles reproducibles
//

import Foundation

struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: String) {
        var hasher = Hasher()
        hasher.combine(seed)
        self.state = UInt64(truncatingIfNeeded: hasher.finalize())
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }

    mutating func next(max: Int) -> Int {
        guard max > 0 else { return 0 }
        return Int(next() % UInt64(max))
    }
}
