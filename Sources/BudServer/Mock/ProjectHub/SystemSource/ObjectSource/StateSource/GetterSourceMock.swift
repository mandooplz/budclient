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
    init(name: String) {
        self.name = name
        
        GetterSourceMockManager.register(self)
    }
    func delete() {
        GetterSourceMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    nonisolated let target = GetterID()
    
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
        fatalError()
    }
    
    package func removeGetter() async {
        fatalError()
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
