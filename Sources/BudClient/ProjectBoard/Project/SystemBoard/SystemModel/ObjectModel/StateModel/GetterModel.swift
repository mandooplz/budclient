//
//  GetterModel.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor @Observable
public final class GetterModel: ObservableObject {
    // MARK: core
    init(target: GetterID) {
        self.target = target
        
        GetterModelManager.register(self)
    }
    func delete() {
        GetterModelManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: GetterID
    
    
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
            GetterModelManager.container[self] != nil
        }
        public var ref: GetterModel? {
            GetterModelManager.container[self]
        }
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class GetterModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [GetterModel.ID: GetterModel] = [:]
    fileprivate static func register(_ object: GetterModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: GetterModel.ID) {
        container[id] = nil
    }
}
