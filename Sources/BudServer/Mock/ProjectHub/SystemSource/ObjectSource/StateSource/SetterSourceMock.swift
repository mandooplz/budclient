//
//  SetterSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/22/25.
//
import Foundation
import Values
import Collections

private let logger = BudLogger("SetterSourceMock")


// MARK: Object
@Server
package final class SetterSourceMock: SetterSourceInterface {
    // MARK: core
    init(name: String) {
        self.name = name
        
        SetterSourceMockManager.register(self)
    }
    func delete() {
        SetterSourceMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    nonisolated let target = SetterID()
    
    var handlers: [ObjectID:EventHandler?] = [:]
    var name: String
    
    var parameters: OrderedDictionary<ValueTypeID, ParameterValue> = [:]
    
    package func setHandler(requester: ObjectID, _ handler: EventHandler) async {
        
        self.handlers[requester] = handler
    }
    
    package func setName(_ value: String) async {
        self.name = value
    }
    

    // MARK: action
    package func notifyStateChanged() async {
        // 바뀐 내용을 전부 알려준다.
        fatalError()
    }

    
    
    // MARK: value
    @Server
    package struct ID: SetterSourceIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            SetterSourceMockManager.container[self] != nil
        }
        package var ref: SetterSourceMock? {
            SetterSourceMockManager.container[self]
        }
    }
    package typealias EventHandler = Handler<SetterSourceEvent>
}


// MARK: ObjectManager
@Server
fileprivate final class SetterSourceMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [SetterSourceMock.ID: SetterSourceMock] = [:]
    fileprivate static func register(_ object: SetterSourceMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SetterSourceMock.ID) {
        container[id] = nil
    }
}

