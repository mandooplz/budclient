//
//  SystemSourceLink.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values


// MARK: Link
@Server
package struct SystemSourceLink: Sendable {
    // MARK: core
    private let mode: SystemMode
    private let object: SystemSourceID
    package nonisolated init(mode: SystemMode, object: SystemSourceID) {
        self.mode = mode
        self.object = object
    }
    
    
    // MARK: state
    func hasHandler(requester: ObjectID) -> Bool {
        fatalError()
    }
    package func setHandler(requester: ObjectID, handler: Handler<SystemSourceEvent>) {
        fatalError()
    }
    package func removeHandler(requester: ObjectID) {
        fatalError()
    }
    
    package func setName(_ value: String) {
        fatalError()
    }
    
    // MARK: action
    package func addSystemRight() { }
    package func addSystemLeft() { }
    package func addSystemTop() { }
    package func addSystemBottom() { }
    
    package func remove() {
        fatalError()
    }
}
