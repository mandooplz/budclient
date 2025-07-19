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
    package init() { }
    
    
    // MARK: state
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
}
