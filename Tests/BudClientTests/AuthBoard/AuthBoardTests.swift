//
//  AuthBoardTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Testing
import BudClient


// MARK: Tests
@Suite("AuthBoard")
struct AuthBoardTests {
    struct SetUpEmailForm {
        let budClientRef: BudClient
        let authBoardRef: AuthBoard
        init() async {
            self.budClientRef = await BudClient()
            self.authBoardRef = await getAuthBoard(self.budClientRef)
        }
        
        @Test func setEmailForm() async throws { }
        @Test func createEmailForm() async throws { }
        
    }
}


// MARK: Helphers
func getAuthBoard(_ budClientRef: BudClient) async -> AuthBoard {
    try! await #require(budClientRef.authBoard == nil)
    
    await budClientRef.setUp()
    
    let authBoard = await budClientRef.authBoard!
    let authBoardRef = await AuthBoardManager.get(authBoard)!
    return authBoardRef
}
