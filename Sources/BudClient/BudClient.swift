//
//  BudClient.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools
import BudServer
import Observation


// MARK: System
@MainActor @Observable
public final class BudClient: Sendable {
    // MARK: core
    public init(mode: SystemMode = .real,
                plistPath: String = "") {
        self.id = ID(value: UUID())
        self.mode = mode
        self.plistPath = plistPath
        
        BudClientManager.register(self)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    private nonisolated let mode: SystemMode
    
    internal nonisolated let plistPath: String
    internal var budServerLink: BudServerLink?
    
    public var authBoard: AuthBoard.ID?
    public var projectBoard: ProjectBoard.ID?
    
    public var issue: Issue?
    
    // MARK: action
    public func setUp() {
        // capture
        if self.authBoard != nil {
            issue = Issue(isKnown: true, reason: Error.alreadySetUp)
            return
        }
        
        // compute
        let budServerLink: BudServerLink
        do {
            budServerLink = try BudServerLink(mode: self.mode, plistPath: plistPath)
        } catch(let error) {
            switch error {
            case .plistPathIsWrong:
                issue = Issue(isKnown: true, reason: Error.invalidPlistPath)
            }
            return
        }
        
        // mutate
        let authBoardRef = AuthBoard(budClient: self.id, mode: self.mode)
        self.authBoard = authBoardRef.id
        self.budServerLink = budServerLink
    }
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
    public enum Error: String, Swift.Error {
        case alreadySetUp
        case invalidPlistPath
    }
}


// MARK: System Manager
@MainActor
public final class BudClientManager: Sendable {
    // MARK: state
    private static var container: [BudClient.ID: BudClient] = [:]
    public static func register(_ object: BudClient) {
        container[object.id] = object
    }
    public static func get(_ id: BudClient.ID) -> BudClient? {
        container[id]
    }
}
