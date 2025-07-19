//
//  BudClienInfoForm.swift
//  BudClient
//
//  Created by 김민우 on 7/18/25.
//
import Foundation
import Values
import FirebaseAuth
import FirebaseCore

private let logger = BudLogger("BudClientInfoForm")


// MARK: Object
@MainActor
package final class BudClienInfoForm: BudClientInfoFormInterface {
    // MARK: core
    package init() {
        BudClientInfoFormManager.register(self)
    }
    package func delete() {
        BudClientInfoFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    package var googleClientId: String?
    
    
    // MARK: action
    package func fetchGoogleClientId() async {
        guard let googleClient = FirebaseApp.app()?.options.clientID else {
            let log = logger.getLog("FirebaseApp이 초기화되지 않아 실행 취소됩니다.")
            logger.raw.error("\(log)")
            return
        }
        
        self.googleClientId = googleClient
    }
    
    
    // MARK: value
    @MainActor
    package struct ID: BudClientInfoFormIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            BudClientInfoFormManager.container[self] != nil
        }
        package var ref: BudClienInfoForm? {
            BudClientInfoFormManager.container[self]
        }
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class BudClientInfoFormManager: Sendable {
    // MARK: state
    fileprivate static var container: [BudClienInfoForm.ID: BudClienInfoForm] = [:]
    fileprivate static func register(_ object: BudClienInfoForm) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: BudClienInfoForm.ID) {
        container[id] = nil
    }
}
