//
//  BudClientInfoFormMock.swift
//  BudClient
//
//  Created by 김민우 on 7/18/25.
//
import Foundation
import Values



// MARK: Object
@MainActor
package final class BudClientInfoFormMock: BudClientInfoFormInterface {
    // MARK: core
    private let logger = BudLogger("BudClientInfoForMock")
    package init() { }
    
    
    // MARK: state
    package var googleClientId: String?
    
    
    // MARK: action
    package func fetchGoogleClientId() async {
        self.googleClientId = "SAMPLE_GOOGLE_CLIENTID"
    }
}

