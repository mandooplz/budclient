//
//  Server.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//


// MARK: Server
@globalActor public final actor Server {
    public static let shared = Server()
    
    @discardableResult
    @Server public static func run<T>(resultType: T.Type = T.self,
                                                  body: @Server () async throws -> T)
    async rethrows -> T where T:Sendable {
        try await body()
    }
}
