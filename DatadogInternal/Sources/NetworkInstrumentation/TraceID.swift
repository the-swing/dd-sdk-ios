/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

public typealias SpanID = TraceID

public struct TraceID: RawRepresentable, Equatable, Hashable {
    public init?(rawValue: String) {
        self.init(rawValue)
    }
    
    /// The `String` representation format of a `TraceID`.
    public enum Representation {
        case decimal
        case hexadecimal
        case hexadecimal16Chars
        case hexadecimal32Chars
    }
    
    public var hexString: String {
        return String(format: "%016llx%016llx", idHi, idLo)
    }

    public static let invalidId: UInt64 = 0
    
    public var rawValue: String {
        hexString
    }

    public private(set) var idHi: UInt64 = invalidId
    public private(set) var idLo: UInt64 = invalidId

    /// Creates a new instance with the specified raw value.
    ///
    /// - Parameter rawValue: The raw value to use for the new instance.
    public init(idHi: UInt64, idLo: UInt64) {
        self.idHi = idHi
        self.idLo = idLo
    }
}

extension TraceID {
    /// Creates a `TraceID` from a `String` representation.
    ///
    /// - Parameters:
    ///   - string: The `String` representation.
    ///   - representation: The representation, `.decimal` by default.
    public init?(_ string: String, representation: Representation = .decimal, withOffset offset: Int = 0) {
        switch representation {
        case .decimal:
            guard let rawValue = UInt64(string) else {
                return nil
            }

            self.init(integerLiteral: rawValue)
        case .hexadecimal, .hexadecimal16Chars, .hexadecimal32Chars:
            let hex = string
            if hex.count >= 32 + offset {
                let firstIndex = hex.index(hex.startIndex, offsetBy: offset)
                let secondIndex = hex.index(firstIndex, offsetBy: 16)
                let thirdIndex = hex.index(secondIndex, offsetBy: 16)
                if let idHi = UInt64(hex[firstIndex ..< secondIndex], radix: 16),
                    let idLo = UInt64(hex[secondIndex ..< thirdIndex], radix: 16) {
                    self.init(idHi: idHi, idLo: idLo)
                    return
                }
            } else if hex.count >= 16 + offset {
                let firstIndex = hex.index(hex.startIndex, offsetBy: offset)
                let secondIndex = hex.index(firstIndex, offsetBy: 16)
                if let idLo = UInt64(hex[firstIndex ..< secondIndex], radix: 16) {
                    self.init(idHi: 0, idLo: idLo)
                    return
                }
            }
            self.init()
        }
    }
    
    public init() {}
}

extension TraceID: ExpressibleByIntegerLiteral {
    /// Creates an instance initialized to the specified integer value.
    ///
    /// Do not call this initializer directly. Instead, initialize a variable or
    /// constant using an integer literal. For example:
    ///
    ///     let id: TraceID = 23
    ///
    /// In this example, the assignment to the `id` constant calls this integer
    /// literal initializer behind the scenes.
    ///
    /// - Parameter value: The value to create.
    public init(integerLiteral value: UInt64) {
        self.init(idHi: TraceID.invalidId, idLo: value)
    }
}

extension String {
    /// Creates a `String` representation of a `TraceID`.
    ///
    /// - Parameters:
    ///   - traceID: The Trace ID
    ///   - representation: The required representation. `.decimal` by default.
    public init(_ traceID: TraceID, representation: TraceID.Representation = .decimal) {
        switch representation {
        case .decimal:
            self.init(traceID.rawValue)
        case .hexadecimal:
            self.init(traceID.rawValue)
        case .hexadecimal16Chars:
            self.init(format: "%016llx", traceID.rawValue)
        case .hexadecimal32Chars:
            self.init(format: "%032llx", traceID.rawValue)
        }
    }
}

/// A `TraceID` generator interface.
public protocol TraceIDGenerator {
    /// Generates a new and unique `TraceID`.
    ///
    /// - Returns: The generated `TraceID`
    func generate() -> TraceID
}

/// A Default `TraceID` genarator.
public struct DefaultTraceIDGenerator: TraceIDGenerator {
    /// Describes the lower and upper boundary of tracing ID generation.
    ///
    /// * Lower: starts with `1` as `0` is reserved for historical reason: 0 == "unset", ref: dd-trace-java:DDId.java.
    /// * Upper: equals to `2 ^ 63 - 1` as some tracers can't handle the `2 ^ 64 -1` range, ref: dd-trace-java:DDId.java.
    public static let defaultGenerationRange = (1...UInt64.max >> 1)

    /// The generator's range.
    let range: ClosedRange<UInt64>

    /// Creates a default generator.
    ///
    /// - Parameter range: The generator's range.
    public init(range: ClosedRange<UInt64> = Self.defaultGenerationRange) {
        self.range = range
    }

    /// Generates a new and unique `TraceID`.
    ///
    /// The Trace ID will be generated within the range.
    ///
    /// - Returns: The generated `TraceID`
    public func generate() -> TraceID {
        var idHi: UInt64
        var idLo: UInt64
        repeat {
            idHi = UInt64.random(in: .min ... .max)
            idLo = UInt64.random(in: .min ... .max)
        } while idHi == TraceID.invalidId && idLo == TraceID.invalidId
        return TraceID(idHi: idHi, idLo: idLo)
   }
}
