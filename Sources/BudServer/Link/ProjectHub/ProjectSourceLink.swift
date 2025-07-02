//
//  ProjectSourceLink.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Foundation
import Tools



// MARK: Link
public struct ProjectSourceLink: Sendable, Hashable {
    // MARK: core
    private let mode: SystemMode
    private let id: String
    public init(mode: SystemMode, id: String) {
        self.mode = mode
        self.id = id
    }
    
    
    // MARK: state
    @Server
    public func getName() async -> String {
        switch mode {
        case .test:
            let mock = ProjectSourceMock.ID(id)
            return mock.ref!.name
        case .real:
            fatalError()
        }
    }
    @Server
    public func setName(_ value: String) async throws {
        switch mode {
        case .test:
            let mock = ProjectSourceMock.ID(id)
            mock.ref?.name = value
        case .real:
            fatalError()
        }
    }
}
