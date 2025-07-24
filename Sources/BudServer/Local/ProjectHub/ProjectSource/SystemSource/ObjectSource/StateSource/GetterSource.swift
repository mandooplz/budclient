//
//  GetterSource.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Collections
import Values

private let logger = BudLogger("GetterSource")


// MARK: Object
@MainActor
package final class GetterSource: GetterSourceInterface {
    // MARK: core
    
    // MARK: state
    nonisolated let id = ID()
    
    package func setName(_ value: String) async {
        fatalError()
    }
    package func setParameters(_ value: OrderedSet<ParameterValue>) async {
        fatalError()
    }
    
    package func appendHandler(requester: ObjectID,
                               _ handler: Handler<GetterSourceEvent>) async {
        fatalError()
    }
    
    // MARK: action
    package func notifyStateChanged() async {
        fatalError()
    }

    package func duplicateGetter() async {
        fatalError()
    }
    package func removeGetter() async {
        fatalError()
    }

    
    // MARK: value
    @MainActor
    package struct ID: GetterSourceIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            GetterSourceManager.container[self] != nil
        }
        package var ref: GetterSource? {
            GetterSourceManager.container[self]
        }
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class GetterSourceManager: Sendable {
    // MARK: state
    fileprivate static var container: [GetterSource.ID: GetterSource] = [:]
    fileprivate static func register(_ object: GetterSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: GetterSource.ID) {
        container[id] = nil
    }
}



