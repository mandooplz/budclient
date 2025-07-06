//
//  SetterModel.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor @Observable
public final class SetterModel: Sendable {
    // MARK:  Core
    init(target: StateID) {
        self.target = target
        
        SetterModelManager.register(self)
    }
    func delete() {
        SetterModelManager.unregister(self.id)
    }
    
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: StateID

    
    // MARK: action
    public func remove() async { }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            SetterModelManager.container[self] != nil
        }
        public var ref: SetterModel? {
            SetterModelManager.container[self]
        }
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class SetterModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [SetterModel.ID: SetterModel] = [:]
    fileprivate static func register(_ object: SetterModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SetterModel.ID) {
        container[id] = nil
    }
}
