//
//  GridLocation.swift
//  BudClient
//
//  Created by 김민우 on 7/6/25.
//


// MARK: GridLocation
public struct GridLocation: Sendable, Hashable {
    public let x: Int
    public let y: Int
    
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

public extension GridLocation {
    static func center() -> Self {
        .init(x: 0, y: 0)
    }
}
