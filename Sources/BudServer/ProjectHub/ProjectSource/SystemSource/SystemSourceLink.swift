//
//  SystemSourceLink.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values
import BudServerMock
import BudServerLocal


// MARK: Link
@Server
package struct SystemSourceLink: Sendable {
    // MARK: core
    private let mode: SystemMode
    private let object: SystemSourceID
    private typealias TestManager = SystemSourceMockManager
    private typealias RealManager = SystemSourceManager
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
    
    package func setName(_ value: String) async {
        switch mode {
        case .test:
            TestManager.get(object)?.name = value
        case .real:
            await MainActor.run {
                RealManager.get(object)?.setName(value)
            }
        }
    }
    
    package func notifyNameChanged() {
        switch mode {
        case .test:
            TestManager.get(object)?.notifyNameChanged()
        case .real:
            return // setName에서 이미 처리됨
        }
    }
    
    // MARK: action
    package func addSystemRight() {
        fatalError()
    }
    package func addSystemLeft() {
        fatalError()
    }
    package func addSystemTop() {
        fatalError()
    }
    package func addSystemBottom() {
        fatalError()
    }
    
    package func remove() {
        fatalError()
    }
}
