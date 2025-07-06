//
//  StateModel.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor @Observable
public final class StateModel: ObservableObject {
    // MARK: core
    init(target: StateID) {
        self.target = target
        
        StateModelManager.register(self)
    }
    func delete() {
        StateModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: StateID
    
    public var permission: Permission = .readWrite
    
    
    // MARK: action
    public func createGetter() async { }
    public func createSetter() async { }
    
    public func remove() { }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            fatalError()
        }
        public var ref: StateModel? {
            fatalError()
        }
    }
    public enum Permission: Sendable, Hashable {
        case none, read, readWrite
    }
}


// MARK: Objec Manager
@MainActor @Observable
fileprivate final class StateModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [StateModel.ID: StateModel] = [:]
    fileprivate static func register(_ object: StateModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: StateModel.ID) {
        container[id] = nil
    }
}
