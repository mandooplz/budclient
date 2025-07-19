//
//  GetterModel.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values
import Collections
import BudServer

private let logger = BudLogger("GetterModel")


// MARK: Object
@MainActor @Observable
public final class GetterModel: Sendable {
    // MARK: core
    init(name: String, target: GetterID) {
        self.target = target
        
        self.name = name
        self.nameInput = name
        
        GetterModelManager.register(self)
    }
    func delete() {
        GetterModelManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: GetterID
    
    public var name: String
    public var nameInput: String
    
    public var paremeters = OrderedDictionary<ValueTypeID, ParameterValue>()
    public var result: ResultValue = .AnyValue
    
    
    // MARK: action
    public func duplicate() async { }
    
    public func removeGetter() async { }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        public var isExist: Bool {
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
