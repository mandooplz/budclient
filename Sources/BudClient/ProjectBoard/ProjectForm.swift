//
//  ProjectForm.swift
//  BudClient
//
//  Created by 김민우 on 7/1/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor @Observable
public final class ProjectForm: Debuggable {
    // MARK: core
    init() {
        self.id = ID(value: UUID())
    }
    
    
    // MARK: state
    internal nonisolated let id: ID
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
}


// MARK: ObjectManager
@MainActor @Observable
fileprivate final class ProjectFormManager: Sendable {
    // MARK: state
    fileprivate static var container: [ProjectForm.ID: ProjectForm] = [:]
    fileprivate static func register(_ object: ProjectForm) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectForm.ID) {
        container[id] = nil
    }
}
