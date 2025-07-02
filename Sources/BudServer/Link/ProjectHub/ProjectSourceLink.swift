//
//  ProjectSourceLink.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Foundation
import Tools


// MARK: Link
public struct ProjectSourceLink: Sendable {
    // MARK: core
    private let mode: Mode
    internal init(mode: Mode) {
        self.mode = mode
    }
    
    
    // MARK: state
    public func getName() async -> String {
        switch mode {
        case .test(let mock):
            return await mock.ref!.name
        case .real:
            fatalError()
        }
    }
    public func setName(_ value: String) async {
        switch mode {
        case .test(let mock):
            await Server.run {
                mock.ref?.name = value
            }
        case .real:
            fatalError()
        }
    }
    
    
    // MARK: mode
    internal enum Mode: Sendable {
        case test(mock: ProjectSourceMock.ID)
        case real
    }
}
