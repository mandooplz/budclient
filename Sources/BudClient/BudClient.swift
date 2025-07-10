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
        let budServer: any BudServerIdentity
        let budCache: any BudCacheIdentity
        do {
            switch mode {
            case .test:
                budServer = await BudServerMock().id
                budCache = await BudCacheMock().id
            case .real:
                budServer = try await BudServer(plistPath: plistPath).id
                budCache = await BudCache().id
            }
        } catch {
            issue = UnknownIssue(error); return
        }
        
        // mutate
        let tempConfig = TempConfig(id, mode, system, budServer, budCache)
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
    let mode: SystemMode
    let system: SystemID
    let budServer: any BudServerIdentity
    let budCache: any BudCacheIdentity
    
    init(_ parent: Parent,
         _ mode: SystemMode,
         _ system: SystemID,
         _ budServer: any BudServerIdentity,
         _ budCache: any BudCacheIdentity) {
        self.parent = parent
        self.mode = mode
        self.system = system
        self.budServer = budServer
        self.budCache = budCache
    }
    
    
    func getConfig<P:Sendable>(_ parent: P, user: UserID) -> Config<P> {
        .init(parent, mode, system, user, budServer, budCache)
    }
    func setParent<P:Sendable>(_ parent: P) -> TempConfig<P> {
        .init(parent, mode, system, budServer, budCache)
    }
}


// MARK: Config
public struct Config<Parent: Sendable> : Sendable{
    public let parent: Parent
    
    let mode: SystemMode
    let system: SystemID
    let user: UserID
    
    let budServer: any BudServerIdentity
    let budCache: any BudCacheIdentity
    
    init(_ parent: Parent,
         _ mode: SystemMode,
         _ system: SystemID,
         _ user: UserID,
         _ budServer: any BudServerIdentity,
         _ budCache: any BudCacheIdentity) {
        self.parent = parent
        self.mode = mode
        self.system = system
        self.user = user
        self.budServer = budServer
        self.budCache = budCache
    }
    
    func getTempConfig<P:Sendable>(_ parent: P) -> TempConfig<P> {
        .init(parent, mode, system, budServer, budCache)
    }
    func setParent<P: Sendable>(_ parent: P) -> Config<P> {
        .init(parent, mode, system, user, budServer, budCache)
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
