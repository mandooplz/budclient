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
        self.mode = .real(plistPath: plistPath)
        self.budCacheMockRef = .shared
        self.budCacheLink = BudCacheLink(mode: .real)
        
        BudClientManager.register(self)
    }
    public init() {
        self.id = ID(value: UUID())
        self.mode = .test
        self.budCacheMockRef = BudCacheMock()
        self.budCacheLink = BudCacheLink(mode: .test(mockRef: budCacheMockRef))
        
        BudClientManager.register(self)
    }
    
    
    // MARK: state
    internal nonisolated let id: ID
    internal nonisolated let mode: Mode
    
    public private(set) var budServerLink: BudServerLink?
    private nonisolated let budCacheMockRef: BudCacheMock
    internal nonisolated let budCacheLink: BudCacheLink
    
    public internal(set) var authBoard: AuthBoard.ID?
    private var isSetUpRequired: Bool { self.authBoard == nil }
    
    public internal(set) var isUserSignedIn: Bool = false
    public internal(set) var projectBoard: ProjectBoard.ID?
    public internal(set) var profileBoard: ProfileBoard.ID?
        
    public private(set) var issue: (any Issuable)?
    public var isIssueOccurred: Bool { issue != nil }
    
    
    // MARK: action
    public func setUp() async {
        // capture
        guard isSetUpRequired else {
        issue = KnownIssue(Error.alreadySetUp)
            return
        }
        
        // compute
        let budServerLink: BudServerLink
        do {
            async let link = try BudServerLink(mode: mode.forBudServerLink)
            budServerLink = try await link
        } catch {
            issue = UnknownIssue(error)
            return
        }
        
        // mutate
        self.budServerLink = budServerLink
        
        let authBoardRef = AuthBoard(budClient: self.id, mode: mode.getSystemMode())
        self.authBoard = authBoardRef.id
    }
    
    
    // MARK: value
    @MainActor public struct ID: Sendable, Hashable {
        public let value: UUID
        
        public var ref: BudClient? {
            BudClientManager.container[self]
        }
    }
    public enum Mode: Sendable {
        case test
        case real(plistPath: String)
        
        var forBudServerLink: BudServerLink.Mode {
            switch self {
            case .test:
                return .test
            case .real(let plistPath):
                return .real(plistPath: plistPath)
            }
        }
        func getSystemMode() -> SystemMode {
            switch self {
            case .test: return .test
            case .real: return .real
            }
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
