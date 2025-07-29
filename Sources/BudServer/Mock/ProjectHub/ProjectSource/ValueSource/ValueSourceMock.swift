//
//  ValueSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/29/25.
//
import Foundation
import Values
import Collections


private let logger = BudLogger("ValueSourceMock")

// MARK: Object
@Server
package final class ValueSourceMock: ValueSourceInterface {
    // MARK: core
    init(owner: ProjectSourceMock.ID) {
        self.owner = owner
        
        ValueSourceMockManager.register(self)
    }
    func delete() {
        ValueSourceMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target = ValueID()
    nonisolated let owner: ProjectSourceMock.ID
    
    nonisolated let createdAt = Date.now
    var updatedAt = Date.now
    var order: Int = 0
    
    var name: String = "New Value"
    var description: String?
    var fields: [ValueField] = []
    
    var handler: EventHandler?
    
    package func setName(_ value: String) async {
        self.name = value
    }
    package func setFields(_ value: [ValueField]) async {
        self.fields = value
    }
    package func setDescription(_ value: String) async {
        self.description = value
    }
    
    package func appendHandler(requester: ObjectID, _ handler: EventHandler) async {
        logger.start()
        
        self.handler = handler
    }
    
    // MARK: action
    package func notifyStateChanged() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ValueSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // notify
        let diff = ValueSourceDiff(self)
        
        self.handler?.execute(.modified(diff))
    }
    
    package func removeValue() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ValueSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let projectSourceRef = self.owner.ref!

        // mutate
        projectSourceRef.values[self.target] = nil
        self.delete()
        
        // notify
        self.handler?.execute(.removed)
    }
    
    // MARK: value
    package typealias EventHandler = Handler<ValueSourceEvent>
    
    @Server
    package struct ID: ValueSourceIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            ValueSourceMockManager.container[self] != nil
        }
        package var ref: ValueSourceMock? {
            ValueSourceMockManager.container[self]
        }
    }
}


// MARK: ObjectManager
@Server
fileprivate final class ValueSourceMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [ValueSourceMock.ID: ValueSourceMock] = [:]
    fileprivate static func register(_ object: ValueSourceMock) {
        self.container[object.id] = object
    }
    fileprivate static func unregister(_ id: ValueSourceMock.ID) {
        self.container[id] = nil
    }
}
