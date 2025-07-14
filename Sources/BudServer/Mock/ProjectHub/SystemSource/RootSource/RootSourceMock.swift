//
//  RootSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values


// MARK: Object
@Server
package final class RootSourceMock: RootSourceInterface {
    // MARK: core
    init(name: String,
         parent: SystemSourceMock.ID,
         target: ObjectID = ObjectID()) {
        self.name = name
        self.parent = parent
        self.target = target
        
        RootSourceMockManager.register(self)
    }
    func delete() {
        RootSourceMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    package nonisolated let parent: SystemSourceMock.ID
    package nonisolated let target: ObjectID
    var name: String
    package func setName(_ value: String) async {
        self.name = value
    }
    
    
    package var actions: [RootActionSourceMock.ID] = []
    package var states: [RootStateSourceMock.ID] = []
    
    
    // MARK: action
    package func createAction() async {
        fatalError()
    }
    package func createState() async {
        fatalError()
    }
    
    
    
    // MARK: value
    @Server
    package struct ID: RootSourceIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            RootSourceMockManager.container[self] != nil
        }
        package var ref: RootSourceMock? {
            RootSourceMockManager.container[self]
        }
    }
}


// MARK: ObjectManager
@Server
fileprivate final class RootSourceMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [RootSourceMock.ID: RootSourceMock] = [:]
    fileprivate static func register(_ object: RootSourceMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: RootSourceMock.ID) {
        container[id] = nil
    }
}
