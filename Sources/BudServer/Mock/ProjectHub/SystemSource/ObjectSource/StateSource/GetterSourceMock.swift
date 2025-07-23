//
//  GetterSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/22/25.
//
import Foundation
import Values
import Collections

private let logger = BudLogger("GetterSourceMock")


// MARK: Object
@Server
package final class GetterSourceMock: GetterSourceInterface {
    // MARK: core
    init(name: String,
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
    
    var handlers: [ObjectID:EventHandler?] = [:]
    var name: String
    package func setName(_ value: String) async {
        self.name = value
    }
    
    var parameters = OrderedDictionary<ValueID, ParameterValue>()
    var result: ValueType = .void
    
    package func appendHandler(requester: ObjectID, _ handler: Handler<GetterSourceEvent>) async {
        
        self.handlers[requester] = handler
    }
    
    // MARK: action
    package func notifyStateChanged() async {
        // 바뀐 내용을 전부 알려준다.
        fatalError()
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
            .forEach {
                $0.execute(.getterDuplicated(self.target, diff))
            }
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
            .forEach { $0?.execute(.removed) }
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
