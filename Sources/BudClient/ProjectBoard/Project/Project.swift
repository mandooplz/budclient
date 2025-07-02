//
//  Project.swift
//  BudClient
//
//  Created by 김민우 on 6/25/25.
//
import Foundation
import Tools
import BudServer


// MARK: Object
@MainActor @Observable
public final class Project: Debuggable {
    
    // MARK: core
    public init(config: Config<ProjectBoard.ID>,
                sourceLink: ProjectSourceLink) {
        self.id = ID(value: .init())
        self.config = config
        self.sourceLink = sourceLink
        
        ProjectManager.register(self)
    }
    public func delete() {
        ProjectManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    internal nonisolated let config: Config<ProjectBoard.ID>
    
    nonisolated let sourceLink: ProjectSourceLink
    
    public var name: String?
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func push() async {
        await self.push(captureHook: nil)
    }
    internal func push(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectIsDeleted); return }
    }
    
    public func removeSource() async {
        await self.removeSource(captureHook: nil)
    }
    internal func removeSource(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectIsDeleted); return }
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        
        internal var isExist: Bool {
            ProjectManager.container[self] != nil
        }
        public var ref: Project? {
            ProjectManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case projectIsDeleted
    }
}

// MARK: Object Manager
@MainActor @Observable
fileprivate final class ProjectManager: Sendable {
    // MARK: state
    fileprivate static var container: [Project.ID: Project] = [:]
    fileprivate static func register(_ object: Project) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: Project.ID) {
        container[id] = nil
    }
}
