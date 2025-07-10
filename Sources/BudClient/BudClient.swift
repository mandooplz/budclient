//
//  BudClient.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Values
import BudServer
import BudCache


// MARK: System
@MainActor @Observable
public final class BudClient: Debuggable {
    // MARK: core
    public init(plistPath: String) {
        self.mode = .real
        self.plistPath = plistPath
        
        BudClientManager.register(self)
    }
    package init() {
        self.mode = .test
        self.plistPath = ""
        
        BudClientManager.register(self)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let mode: SystemMode
    nonisolated let system = SystemID()
    
    private nonisolated let plistPath: String
    private nonisolated let budServerMockRef = BudServerMock()
    private nonisolated let budCacheMockRef = BudCacheMock()
    
    public internal(set) var authBoard: AuthBoard.ID?
    public internal(set) var projectBoard: ProjectBoard.ID?
    public internal(set) var profileBoard: ProfileBoard.ID?
    public internal(set) var community: Community.ID?
    var user: UserID? = nil
    public var isUserSignedIn: Bool { user != nil }
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func setUp() async {
        // capture
        guard authBoard == nil && projectBoard == nil && profileBoard == nil
        else { setIssue(Error.alreadySetUp); return }
        
        // compute
        let budServerLink: BudServerLink
        let budCacheLink: BudCacheLink
        do {
            switch mode {
            case .test:
                budServerLink = await .init(budServerMockRef: budServerMockRef)
                budCacheLink = BudCacheLink(mode: .test, budCacheMockRef: self.budCacheMockRef)
            case .real:
                budServerLink = try await .init(plistPath: plistPath)
                budCacheLink = BudCacheLink(mode: .real, budCacheMockRef: self.budCacheMockRef)
            }
        } catch {
            issue = UnknownIssue(error); return
        }
        
        // mutate
        let tempConfig = TempConfig(id, mode, system, budServerLink, budCacheLink)
        let authBoardRef = AuthBoard(tempConfig: tempConfig)
        self.authBoard = authBoardRef.id
    }
    
    
    // MARK: value
    @MainActor public struct ID: Sendable, Hashable {
        public let value: UUID
        nonisolated init(_ value: UUID = UUID()) {
            self.value = value
        }
        
        public var ref: BudClient? {
            BudClientManager.container[self]
        }
    }
    
    public enum Error: String, Swift.Error {
        case alreadySetUp
        case invalidPlistPath
    }
}



// MARK: TempConfig
public struct TempConfig<Parent: Sendable>: Sendable {
    public let parent: Parent
    public let mode: SystemMode
    public let system: SystemID
    let budServerLink: BudServerLink
    let budCacheLink: BudCacheLink
    
    init(_ parent: Parent,
         _ mode: SystemMode,
         _ system: SystemID,
         _ budServerLink: BudServerLink,
         _ budCacheLink: BudCacheLink) {
        self.parent = parent
        self.mode = mode
        self.system = system
        self.budServerLink = budServerLink
        self.budCacheLink = budCacheLink
    }
    
    
    func getConfig<P:Sendable>(_ parent: P, user: UserID) -> Config<P> {
        .init(parent, mode, system, user, budServerLink, budCacheLink)
    }
    func setParent<P:Sendable>(_ parent: P) -> TempConfig<P> {
        .init(parent, mode, system, budServerLink, budCacheLink)
    }
}


// MARK: Config
public struct Config<Parent: Sendable> : Sendable{
    public let parent: Parent
    
    public let mode: SystemMode
    public let system: SystemID
    public let user: UserID
    
    let budServerLink: BudServerLink
    let budCacheLink: BudCacheLink
    
    init(_ parent: Parent,
         _ mode: SystemMode,
         _ system: SystemID,
         _ user: UserID,
         _ budSeverLink: BudServerLink,
         _ budCacheLink: BudCacheLink) {
        self.parent = parent
        self.mode = mode
        self.system = system
        self.user = user
        self.budServerLink = budSeverLink
        self.budCacheLink = budCacheLink
    }
    
    func getTempConfig<P:Sendable>(_ parent: P) -> TempConfig<P> {
        .init(parent, mode, system, budServerLink, budCacheLink)
    }
    func setParent<P: Sendable>(_ parent: P) -> Config<P> {
        .init(parent, mode, system, user, budServerLink, budCacheLink)
    }
}





// MARK: System Manager
@MainActor @Observable
fileprivate final class BudClientManager: Sendable {
    // MARK: state
    fileprivate static var container: [BudClient.ID: BudClient] = [:]
    fileprivate static func register(_ object: BudClient) {
        container[object.id] = object
    }
}
