//
//  ProjectBoard.swift
//  BudClient
//
//  Created by 김민우 on 6/25/25.
//
import Foundation
import Tools
import BudServer


// MARK: Object
@MainActor @Observable
public final class ProjectBoard: Sendable {
    // MARK: core
    init(mode: SystemMode, budClient: BudClient.ID, userId: String) {
        self.id = ID(value: .init())
        self.mode = mode
        self.budClient = budClient
        self.userId = userId
        
        ProjectBoardManager.register(self)
    }
    internal func delete() {
        ProjectBoardManager.unregister(self.id)
    }
    
    
    // MARK: state
    internal nonisolated let id: ID
    internal nonisolated let mode: SystemMode
    public nonisolated let budClient: BudClient.ID
    
    public nonisolated let userId: String
    internal var updater: ProjectBoardUpdater.ID?
    
    public internal(set) var projects: [Project.ID] = []
    internal var projectSourceMap: [ProjectSourceID: Project.ID] = [:]
    
    public var issue: (any Issuable)?
    
    internal var debugIssue: (any Issuable)?
    private func setDebugIssue(_ error: Error) {
        self.debugIssue = KnownIssue(error)
    }
    
    
    // MARK: action
    public func setUpUpdater() async {
        await setUpUpdater(mutateHook: nil)
    }
    internal func setUpUpdater(mutateHook: Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setDebugIssue(.projectBoardIsDeleted); return }
        guard self.updater == nil else { return }
        
        let updaterRef = ProjectBoardUpdater(mode: mode,
                                             projectBoard: self.id)
        self.updater = updaterRef.id
    }
    
    public func subscribeProjectHub() async {
        await self.subscribeProjectHub(addCallback: nil, removeCallback: nil)
    }
    internal func subscribeProjectHub(addCallback: Hook? = nil,
                                 removeCallback: Hook? = nil,
                                 captureHook: Hook? = nil) async {
        // capture
        await captureHook?()
        guard id.isExist else { setDebugIssue(.projectBoardIsDeleted); return}
        let budServerLink = budClient.ref!.budServerLink!
        let projectHubLink = budServerLink.getProjectHub()
        
        // compute
        do {
            try await projectHubLink.setNotifier(
                userId: userId,
                notifier: .init(
                    added: { projectSource in
                        Task { @MainActor in
                            // 이를 더 간단히 작성할 방법은 없을까.
                            guard let updaterRef = self.updater?.ref else { return }
                            
                            updaterRef.diffs.insert(.added(projectSource: projectSource))
                            updaterRef.update()
                            
                            await addCallback?()
                        }
                    },
                    removed: { projectSource in
                        Task { @MainActor in
                            guard let updaterRef = self.updater?.ref else { return }
                            updaterRef.diffs.insert(.removed(projectSource: projectSource))
                            updaterRef.update()
                            await removeCallback?()
                        }
                    }))
        } catch {
            issue = UnknownIssue(error)
            return
        }
    }
    
    public func unsubscribeProjectHub() async {
        await unsubscribeProjectHub(captureHook: nil)
    }
    internal func unsubscribeProjectHub(captureHook: Hook? = nil) async {
        // capture
        await captureHook?()
        guard id.isExist else { setDebugIssue(.projectBoardIsDeleted); return}
        let budServerLink = budClient.ref!.budServerLink!
        let projectHubLink = budServerLink.getProjectHub()
        
        // compute
        do {
            try await projectHubLink.removeNotifier(userId: userId)
        } catch {
            issue = UnknownIssue(error)
            return
        }
    }
    
    public func createProjectSource() async {
        // capture
        let budServerLink = budClient.ref!.budServerLink!
        let projectHubLink = budServerLink.getProjectHub()
        
        // compute
        do {
            let ticket = ProjectHubLink.Ticket(userId: userId, for: .createProjectSource)
            await projectHubLink.insertTicket(ticket)
            try await projectHubLink.processTicket()
        } catch {
            issue = UnknownIssue(error)
            return
        }
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        
        internal var isExist: Bool {
            ProjectBoardManager.container[self] != nil
        }
        public var ref: ProjectBoard? {
            ProjectBoardManager.container[self]
        }
    }
    internal typealias ProjectSourceID = String
    public enum Error: String, Swift.Error {
        case projectBoardIsDeleted
        case updaterIsNotSet
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class ProjectBoardManager: Sendable {
    // MARK: state
    fileprivate static var container: [ProjectBoard.ID: ProjectBoard] = [:]
    fileprivate static func register(_ object: ProjectBoard) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectBoard.ID) {
        container[id] = nil
    }
}

