//
//  Location.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//


// MARK: Value
public struct Location: Sendable, Hashable, Codable {
    public let x: Int
    public let y: Int
    
    
    // MARK: core
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
    
    public static var origin: Self {
        .init(x: 0, y: 0)
    }
    
    
    // MARK: operator
    public func getRight() -> Self {
        return .init(x: self.x + 1, y: self.y)
    }
    
    public func getLeft() -> Self {
        return .init(x: self.x - 1, y: self.y)
    }
    
    public func getTop() -> Self {
        return .init(x: self.x, y: self.y + 1)
    }
    
    public func getBotttom() -> Self {
        return .init(x: self.x, y: self.y - 1)
    }
    
    public func encode() -> [String: Int] {
        return ["x": self.x, "y": self.y]
    }
}


// MARK: Extension
public extension Set<Location> {
    func encode() -> [[String: Int]] {
        self.map { $0.encode() }
    }
}
