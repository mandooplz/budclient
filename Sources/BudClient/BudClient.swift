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
    public init() {
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
    @MainActor public struct ID: Sendable, Hashable {
        public let value: UUID
        
        public var ref: BudClient? {
            BudClientManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case alreadySetUp
        case invalidPlistPath
    }
}


// MARK: System Manager
@MainActor
fileprivate final class BudClientManager: Sendable {
    // MARK: state
    fileprivate static var container: [BudClient.ID: BudClient] = [:]
    fileprivate static func register(_ object: BudClient) {
        container[object.id] = object
    }
}
