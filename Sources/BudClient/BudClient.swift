//
//  BudClient.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools
import BudServer
import BudCache
import Observation


// MARK: System
@MainActor @Observable
public final class BudClient: Sendable {
    // MARK: core
    public init(plistPath: String) {
        self.id = ID(value: UUID())
        self.mode = .real
        self.plistPath = plistPath
        self.budCacheMockRef = .shared
        self.budCacheLink = BudCacheLink(mode: self.mode,
                                         budCacheMockRef: .shared)
        
        BudClientManager.register(self)
    }
    internal init() {
        self.id = ID(value: UUID())
        self.mode = .test
        self.plistPath = ""
        self.budCacheMockRef = BudCacheMock()
        self.budCacheLink = BudCacheLink(mode: self.mode,
                                         budCacheMockRef: budCacheMockRef)
        
        BudClientManager.register(self)
    }
    
    
    
    // MARK: state
    internal nonisolated let id: ID
    internal nonisolated let mode: SystemMode
    
    private nonisolated let plistPath: String
    internal private(set) var budServerLink: BudServerLink?
    internal nonisolated let budCacheMockRef: BudCacheMock
    internal nonisolated let budCacheLink: BudCacheLink
    
    public internal(set) var authBoard: AuthBoard.ID?
    public var isSetupRequired: Bool { authBoard == nil }
    
    public internal(set) var isUserSignedIn: Bool = false
    public internal(set) var projectBoard: ProjectBoard.ID?
    public internal(set) var profileBoard: ProfileBoard.ID?
        
    public private(set) var issue: (any Issuable)?
    public var isIssueOccurred: Bool { issue != nil }
    
    
    // MARK: action
    public func setUp() {
        // capture
        guard self.isSetupRequired else {
            self.issue = KnownIssue(Error.alreadySetUp)
            return
        }
        
        // compute
        let budServerLink: BudServerLink
        do {
            budServerLink = try BudServerLink(mode: self.mode,
                                              plistPath: self.plistPath)
        } catch(let error) {
            switch error {
            case .plistPathIsWrong:
                self.issue = KnownIssue(Error.invalidPlistPath)
                return
            }
        }
        
        // mutate
        self.budServerLink = budServerLink
        
        let authBoardRef = AuthBoard(budClient: self.id, mode: self.mode)
        self.authBoard = authBoardRef.id
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
