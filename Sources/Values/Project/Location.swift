//
//  Location.swift
//  BudClient
//
//  Created by 김민우 on 7/6/25.
//


// MARK: Location
public struct Location: Sendable, Hashable, Codable {
    public let x: Int
    public let y: Int
    
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

public extension Location {
    static var origin: Self {
        .init(x: 0, y: 0)
    }
}

public extension Location {
    func getRight() -> Self {
        return .init(x: self.x + 1, y: self.y)
    }
    
    func getLeft() -> Self {
        return .init(x: self.x - 1, y: self.y)
    }
    
    func getUp() -> Self {
        return .init(x: self.x, y: self.y + 1)
    }
    
    func getDown() -> Self {
        return .init(x: self.x, y: self.y - 1)
    }
}
