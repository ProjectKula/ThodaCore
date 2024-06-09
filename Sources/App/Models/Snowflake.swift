//
//  Snowflake.swift
//
//
//  Created by Shrish Deshpande on 18/05/24.
//

import Atomics
import Foundation

public struct Snowflake {
    // Beginning of the epoch - 25th September 2023
    public static let epoch = Date(timeIntervalSince1970: 1695600000)
    public static var counter: ManagedAtomic<UInt16> = .init(1)

    public let timestamp: Int64
    public let increment: UInt16
    public let rawValue: UInt64
    
    public var stringValue: String {
        return String(rawValue, radix: 10)
    }

    public init() {
        let now = Date()
        let time = Int64(now.timeIntervalSince(Snowflake.epoch) * 1000)
        let counter = Snowflake.counter.loadThenWrappingIncrement(ordering: .relaxed)
        if counter == 4095 {
            Snowflake.counter.store(1, ordering: .relaxed)
        }
        self.timestamp = time
        self.increment = counter
        self.rawValue = UInt64(time << 22) | UInt64(counter)
    }

    private init(rawValue: UInt64) {
        self.rawValue = rawValue
        self.timestamp = Int64(rawValue >> 22)
        self.increment = UInt16(rawValue & 0xFFF)
    }
}
