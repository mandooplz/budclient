//
//  ObjectModel.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor @Observable
public final class ObjectModel: Sendable {
    // MARK: core
    init(target: ObjectID) {
        self.target = target
        
        ObjectModelManager.register(self)
    }
    func delete() {
        ObjectModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: ObjectID // 어떤 Object인지를 표현하는 ID
    
    public var type: ObjectModelType = .oneToOne // Object가 상위 Object와 어떻게 연결되어있는지를 표현
    
    
    // MARK: action
    public func appendChild() { }
    public func appendParent() { }
    
    public func newState() { }
    public func newAction() { }
    
    public func makeFlow() { }
    
    public func remove() { }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            ObjectModelManager.container[self] != nil
        }
        var ref: ObjectModel? {
            ObjectModelManager.container[self]
        }
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class ObjectModelManager: Sendable {
    fileprivate static var container: [ObjectModel.ID: ObjectModel] = [:]
    fileprivate static func register(_ object: ObjectModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ObjectModel.ID) {
        container[id] = nil
    }
}
