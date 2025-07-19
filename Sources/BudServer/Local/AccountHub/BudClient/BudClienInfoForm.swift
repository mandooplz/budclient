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



// MARK: Object
@MainActor
package final class BudClienInfoForm: BudClientInfoFormInterface {
    // MARK: core
    private let logger = BudLogger("BudClientInfoForm")
    package init() { }
    
    
    // MARK: state
    package var googleClientId: String?
    
    
    // MARK: action
    package func fetchGoogleClientId() async {
        guard let googleClient = FirebaseApp.app()?.options.clientID else {
            logger.failure("FirebaseApp이 초기화되지 않아 실행 취소됩니다.")
            return
        }
        
        self.googleClientId = googleClient
    }
}
