//
//  BudServer.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//


// MARK: Server
@globalActor public final actor BudServer {
    public static let shared = BudServer()
    
    @discardableResult
    @BudServer public static func run<T>(resultType: T.Type = T.self,
                                                  body: @BudServer () async throws -> T)
    async rethrows -> T where T:Sendable {
        try await body()
    }
}
