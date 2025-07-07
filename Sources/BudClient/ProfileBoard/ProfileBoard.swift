//
//  ProfileBoard.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Foundation
import Values
import BudServer


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
        do {
            try await config.budCacheLink.resetUser()
        } catch {
            setUnknownIssue(error); return
        }

        
        // mutate
        await mutateHook?()
        guard self.id.isExist else { setIssue(Error.profileBoardIsDeleted); return }
        let budClientRef = self.config.parent.ref!
        let projectBoardRef = projectBoard!.ref!
        let projects = projectBoardRef.projects
        let communityRef = community!.ref!
        let authBoardRef = AuthBoard(tempConfig: tempConfig)
        
        budClientRef.authBoard = authBoardRef.id
        budClientRef.projectBoard = nil
        budClientRef.profileBoard = nil
        budClientRef.user = nil
        
        for project in projects {
            project.ref?.systemBoard?.ref?.delete()
            project.ref?.flowBoard?.ref?.delete()
            project.ref?.updater?.ref?.delete()
            project.ref?.delete()
        }
        
        projectBoardRef.delete()
        projectBoardRef.updater?.ref?.delete()
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
