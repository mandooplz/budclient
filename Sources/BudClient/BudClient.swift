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

private let logger = BudLogger("BudClient")


// MARK: System
@MainActor @Observable
public final class BudClient: Debuggable {
    // MARK: core
    public init(plistPath: String) {
        self.mode = .real
        self.plistPath = plistPath
        
        BudClientManager.register(self)
    }
    public init() {
        self.mode = .test
        self.plistPath = ""
        
        BudClientManager.register(self)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let mode: SystemMode
    private nonisolated let plistPath: String
    var tempConfig: TempConfig<BudClient.ID>?
    
    public internal(set) var signInForm: SignInForm.ID?
    public internal(set) var projectBoard: ProjectBoard.ID?
    public internal(set) var profile: Profile.ID?
    public internal(set) var community: Community.ID?
    
    var user: UserID? = nil
    public var isUserSignedIn: Bool { user != nil }
    
    public var issue: (any IssueRepresentable)?
    
    
    // MARK: action
    public func setUp() async {
        logger.start()
        
        // capture
        guard signInForm == nil && projectBoard == nil && profile == nil
        else {
            setIssue(Error.alreadySetUp)
            logger.failure(Error.alreadySetUp)
            return
        }
        
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
                budCache = BudCache().id
            }
        } catch {
            setUnknownIssue(error)
            logger.failure(error)
            return
        }
        
        // mutate
        let tempConfig = TempConfig(id, mode, budServer, budCache)
        self.tempConfig = tempConfig
        
        let signInFormRef = SignInForm(tempConfig: tempConfig)
        self.signInForm = signInFormRef.id
    }
    public func saveUserInCache() async {
        // capture
        guard let tempConfig else {
            setIssue(Error.setUpRequired)
            logger.failure("BudClient.setUp() 호출이 필요합니다.")
            return
        }
        
        
        guard let user else {
            setIssue(Error.signInRequired)
            logger.failure("SignIn을 통해 User 정보를 가져와야 합니다.")
            return
        }
        
        // compute
        guard let budCacheRef = await tempConfig.budCache.ref else {
            logger.failure("BudCache가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        await budCacheRef.setUser(user)
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        nonisolated init(_ value: UUID = UUID()) {
            self.value = value
        }
        
        public var ref: BudClient? {
            BudClientManager.container[self]
        }
    }
    
    public enum Error: String, Swift.Error {
        case setUpRequired, signInRequired
        case alreadySetUp
        case invalidPlistPath
    }
}



// MARK: TempConfig
public struct TempConfig<Parent: Sendable>: Sendable {
    public let parent: Parent
    let mode: SystemMode
    let budServer: any BudServerIdentity
    let budCache: any BudCacheIdentity
    
    init(_ parent: Parent,
         _ mode: SystemMode,
         _ budServer: any BudServerIdentity,
         _ budCache: any BudCacheIdentity) {
        self.parent = parent
        self.mode = mode
        self.budServer = budServer
        self.budCache = budCache
    }
    
    
    func getConfig<P:Sendable>(_ parent: P, user: UserID) -> Config<P> {
        .init(parent, mode, user, budServer, budCache)
    }
    func setParent<P:Sendable>(_ parent: P) -> TempConfig<P> {
        .init(parent, mode, budServer, budCache)
    }
}


// MARK: Config
public struct Config<Parent: Sendable> : Sendable{
    public let parent: Parent
    
    let mode: SystemMode
    let user: UserID
    
    let budServer: any BudServerIdentity
    let budCache: any BudCacheIdentity
    
    init(_ parent: Parent,
         _ mode: SystemMode,
         _ user: UserID,
         _ budServer: any BudServerIdentity,
         _ budCache: any BudCacheIdentity) {
        self.parent = parent
        self.mode = mode
        self.user = user
        self.budServer = budServer
        self.budCache = budCache
    }
    
    func getTempConfig<P:Sendable>(_ parent: P) -> TempConfig<P> {
        .init(parent, mode, budServer, budCache)
    }
    func setParent<P: Sendable>(_ parent: P) -> Config<P> {
        .init(parent, mode, user, budServer, budCache)
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
