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
    
    
    // MARK: mode
    internal enum Mode: Sendable {
        case test(mock: ProjectSourceMock.ID)
        case real
    }
}
