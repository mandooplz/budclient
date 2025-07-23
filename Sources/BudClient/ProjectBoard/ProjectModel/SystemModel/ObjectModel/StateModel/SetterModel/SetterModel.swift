//
//  SetterModel.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values
import BudServer

private let logger = BudLogger("SetterModel")


// MARK: Object
@MainActor @Observable
public final class SetterModel: Sendable {
    // MARK: core
    init(config: Config<StateModel.ID>,
         diff: SetterSourceDiff) {
        self.target = diff.target
        self.config = config
        
        self.name = diff.name
        self.nameInput = diff.name
        
        self.updaterRef = Updater(owner: self.id)
        
        SetterModelManager.register(self)
    }
    func delete() {
        SetterModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: SetterID
    nonisolated let config: Config<StateModel.ID>
    nonisolated let updaterRef: Updater
    var isUpdating: Bool = false
    
    public internal(set) var name: String
    public var nameInput: String
    
    public var parameters: [ParameterValue] = [.anyParameter]
    
    
    // MARK: action
    public func duplicate() async {
        fatalError()
    }
    
    public func removeSetter() async {
        fatalError()
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        public var isExist: Bool {
            SetterModelManager.container[self] != nil
        }
        public var ref: SetterModel? {
            SetterModelManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case setterModelIsDeleted
        case nameCannotBeEmpty, newNameIsSameAsCurrent
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

