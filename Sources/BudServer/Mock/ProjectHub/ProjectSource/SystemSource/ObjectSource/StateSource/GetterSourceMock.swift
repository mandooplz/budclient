//
//  GetterSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/22/25.
//
import Foundation
import Values

private let logger = BudLogger("GetterSourceMock")


// MARK: Object
@Server
package final class GetterSourceMock: GetterSourceInterface {
    // MARK: core
    init(name: String = "New Getter",
         owner: StateSourceMock.ID) {
        self.name = name
        self.owner = owner
        
        GetterSourceMockManager.register(self)
    }
    func delete() {
        GetterSourceMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    nonisolated let target = GetterID()
    nonisolated let owner: StateSourceMock.ID
    
    nonisolated let createdAt: Date = .now
    var updatedAt: Date = .now
    var order: Int = 0
    
    var handlers: [ObjectID:EventHandler] = [:]
    var name: String
    package func setName(_ value: String) async {
        self.name = value
    }
    
    var parameters: [ParameterValue] = [
        .init(name: "name", type: .stringValue),
        .init(name: "age", type: .intValue),
        .init(name: "address", type: .stringValue),
        .init(name: "year", type: .intValue)
    ]
    package func setParameters(_ value: [ParameterValue]) {
        self.parameters = value
    }
    
    var result: ValueID = .voidValue
    package func setResult(_ value: ValueID) async {
        self.result = value
    }
    
    package func appendHandler(requester: ObjectID, _ handler: Handler<GetterSourceEvent>) async {
        
        self.handlers[requester] = handler
    }
    
    // MARK: action
    package func notifyStateChanged() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("GetterSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // notify
        let diff = GetterSourceDiff(self)
        self.handlers.values
            .forEach { $0.execute(.modified(diff)) }
        
    }
    
    package func duplicateGetter() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("GetterSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let stateSourceRef = self.owner.ref!
        
        // mutate
        let newGetterSourceRef = GetterSourceMock(
            name: self.name,
            owner: self.owner)
        
        
        // notify
        let diff = GetterSourceDiff(newGetterSourceRef)
        
        stateSourceRef.handlers.values
            .forEach { $0.execute(.getterAdded(diff))}
    }
    
    package func removeGetter() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("GetterSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let stateSourceRef = self.owner.ref!
        
        // mutate
        stateSourceRef.getters[self.target] = nil
        self.delete()
        
        // notify
        self.handlers.values
            .forEach { $0.execute(.removed) }
    }

    
    
    // MARK: value
    @Server
    package struct ID: GetterSourceIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            GetterSourceMockManager.container[self] != nil
        }
        package var ref: GetterSourceMock? {
            GetterSourceMockManager.container[self]
        }
    }
    typealias EventHandler = Handler<GetterSourceEvent>
}


// MARK: ObjectManager
@Server
fileprivate final class GetterSourceMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [GetterSourceMock.ID: GetterSourceMock] = [:]
    fileprivate static func register(_ object: GetterSourceMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: GetterSourceMock.ID) {
        container[id] = nil
    }
}
