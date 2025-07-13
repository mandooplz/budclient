//
//  ProfileBoard.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Foundation
import Values
import BudServer

private let logger = WorkFlow.getLogger(for: "ProfileBoard")


// MARK: Object
@MainActor @Observable
public final class ProfileBoard: Debuggable {
    // MARK: core
    init(config: Config<BudClient.ID>) {
        self.config = config

        ProfileBoardManager.register(self)
    }
    func delete() {
        ProfileBoardManager.unregister(self.id)
    }

    
    // MARK: state
    public nonisolated let id = ID()
    public nonisolated let config: Config<BudClient.ID>
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func signOut() async {
        logger.start()
        
        await signOut(captureHook: nil, mutateHook: nil)
    }
    func signOut(captureHook: Hook?, mutateHook: Hook?) async {
        // capture
        await captureHook?()
        guard self.id.isExist else { setIssue(Error.profileBoardIsDeleted); return }
        let config = self.config
        let budClient = config.parent
        let projectBoard = budClient.ref!.projectBoard
        let community = budClient.ref!.community
        
        
        // compute
        let tempConfig = config.getTempConfig(config.parent)
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let budCacheRef = await config.budCache.ref else { return }
                
                await budCacheRef.removeUser()
            }
        }

        
        // mutate
        await mutateHook?()
        guard self.id.isExist else { setIssue(Error.profileBoardIsDeleted); return }
        let budClientRef = self.config.parent.ref!
        let projectBoardRef = projectBoard!.ref!
        let projectEditors = projectBoardRef.editors
        let communityRef = community!.ref!
        let authBoardRef = AuthBoard(tempConfig: tempConfig)
        
        budClientRef.authBoard = authBoardRef.id
        budClientRef.projectBoard = nil
        budClientRef.profileBoard = nil
        budClientRef.user = nil
        
        for projectEditor in projectEditors {
            let systemBoardRef = projectEditor.ref?.systemBoard?.ref
            systemBoardRef?.models.values.forEach { systemModel in
                systemModel.ref?.delete()
            }
            
            systemBoardRef?.delete()
            
            projectEditor.ref?.systemBoard?.ref?.delete()
            projectEditor.ref?.flowBoard?.ref?.delete()
            projectEditor.ref?.valueBoard?.ref?.delete()
            
            projectEditor.ref?.delete()
        }
        
        projectBoardRef.delete()
        communityRef.delete()
        self.delete()
    }


    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            ProfileBoardManager.container[self] != nil
        }
        public var ref: ProfileBoard? {
            ProfileBoardManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case profileBoardIsDeleted
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class ProfileBoardManager: Sendable {
    // MARK: state
    fileprivate static var container: [ProfileBoard.ID: ProfileBoard] = [:]
    fileprivate static func register(_ object: ProfileBoard) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProfileBoard.ID) {
        container[id] = nil
    }
}
