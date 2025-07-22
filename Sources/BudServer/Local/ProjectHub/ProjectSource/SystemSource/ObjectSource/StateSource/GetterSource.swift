//
//  GetterSource.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values

private let logger = BudLogger("GetterSource")


// MARK: Object
@MainActor
package final class GetterSource: Sendable {
    // MARK: core
    
    // MARK: state
    nonisolated let id = ID()
    
    // MARK: action
    
    // MARK: value
    @MainActor
    package struct ID: Sendable, Hashable {
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



