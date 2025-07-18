//
//  Profile.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Foundation
import Values
import BudServer

private let logger = BudLogger("Profile")


// MARK: Object
@MainActor @Observable
public final class Profile: Debuggable {
    // MARK: core
    init(config: Config<BudClient.ID>) {
        self.config = config

        ProfileManager.register(self)
    }
    func delete() {
        ProfileManager.unregister(self.id)
    }

    
    // MARK: state
    public nonisolated let id = ID()
    public nonisolated let config: Config<BudClient.ID>
    
    public var issue: (any IssueRepresentable)?
    
    
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
        let projectModels = projectBoardRef.projects
        let communityRef = community!.ref!
        
        let newSignInFormRef = SignInForm(tempConfig: tempConfig)
        
        budClientRef.signInForm = newSignInFormRef.id
        budClientRef.projectBoard = nil
        budClientRef.profile = nil
        budClientRef.user = nil
        
        for projectModel in projectModels.values {
            projectModel.ref?.systems.values.forEach { systemModel in
                systemModel.ref?.delete()
            }
            
            projectModel.ref?.workflows.values.forEach { workflowModel in
                workflowModel.ref?.delete()
            }
            
            projectModel.ref?.valueTypes.values.forEach { valueTypeModel in
                valueTypeModel.ref?.delete()
            }
            
            projectModel.ref?.delete()
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
            ProfileManager.container[self] != nil
        }
        public var ref: Profile? {
            ProfileManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case profileBoardIsDeleted
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class ProfileManager: Sendable {
    // MARK: state
    fileprivate static var container: [Profile.ID: Profile] = [:]
    fileprivate static func register(_ object: Profile) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: Profile.ID) {
        container[id] = nil
    }
}
