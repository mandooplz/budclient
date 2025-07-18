//
//  BudClientInfoFormMock.swift
//  BudClient
//
//  Created by 김민우 on 7/18/25.
//
import Foundation
import Values

private let logger = WorkFlow.getLogger(for: "BudClientInfoForMock")


// MARK: Object
@MainActor
package final class BudClientInfoFormMock: BudClientInfoFormInterface {
    // MARK: core
    package init() {
        BudClientInfoFormMockManager.register(self)
    }
    package func delete() {
        BudClientInfoFormMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    package var googleClientId: String?
    
    
    // MARK: action
    package func fetchGoogleClientId() async {
        self.googleClientId = "SAMPLE_GOOGLE_CLIENTID"
    }
    
    
    // MARK: value
    @MainActor
    package struct ID: BudClientInfoFormIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            BudClientInfoFormMockManager.container[self] != nil
        }
        package var ref: BudClientInfoFormMock? {
            BudClientInfoFormMockManager.container[self]
        }
    }
    enum Error: String, Swift.Error {
        case firebaseAppIsNotConfigured
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class BudClientInfoFormMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [BudClientInfoFormMock.ID: BudClientInfoFormMock] = [:]
    fileprivate static func register(_ object: BudClientInfoFormMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: BudClientInfoFormMock.ID) {
        container[id] = nil
    }
}

