//
//  SystemModel.swift
//  BudClient
//
//  Created by 김민우 on 7/5/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor @Observable
public final class SystemModel: Sendable {
    // MARK: core
    public init(location: GridLocation, target: SystemID) {
        self.location = location
        self.target = target
        
        SystemModelManager.register(self)
    }
    public func delete() {
        SystemModelManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: SystemID
    
    public var location: GridLocation
    
    public var name: String? // ex) BudClient-iOS, BudClient-MacOS 처럼 시스템의 이름
    
    
    // MARK: action
    public func addSystemRight() { }
    public func addSystemLeft() { }
    public func addSystemTop() { }
    public func addSystemBottom() { }
    
    public func createNewObjectModel() { }
    
    public func remove() { }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            SystemModelManager.container[self] != nil
        }
        public var ref: SystemModel? {
            SystemModelManager.container[self]
        }
    }
}

// MARK: Object Manager
@MainActor @Observable
fileprivate final class SystemModelManager: Sendable {
    fileprivate static var container: [SystemModel.ID: SystemModel] = [:]
    fileprivate static func register(_ object: SystemModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SystemModel.ID) {
        container[id] = nil
    }
}
