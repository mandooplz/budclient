//
//  GoogleFormTests.swift
//  BudClient
//
//  Created by 김민우 on 6/28/25.
//
import Testing
import Foundation
import Tools
import BudClient


// MARK: Tests
@Suite("GoogleForm")
struct GoogleFormTests {
    struct SignIn {
        let budClientRef: BudClient
        let googleFormRef: GoogleForm
        init() async {
            self.budClientRef = await BudClient()
            self.googleFormRef = await getGoogleForm(budClientRef)
        }
        @Test func whenIdTokenIsNil() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = nil
            }
            
            // when
            await googleFormRef.signIn()
            
            // then
            let issue = try #require(await googleFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "idTokenIsNil")
        }
        @Test func whenAccessTokenIsNil() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = nil
            }
            
            // when
            await googleFormRef.signIn()
            
            // then
            let issue = try #require(await googleFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "accessTokenIsNil")
        }
        
        // GoogleForm.SignIn이 호출되면 BudCache에 Token이 저장된다.
        /// 1. EmailForm, SignUpForm 제거
        /// 2. GoogleForm 제거
        /// 3. AuthBoard 제거
        
        @Test func deleteEmailForm() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            
            // when
            await googleFormRef.signIn()
        }
        @Test func deleteSignUpForm() async throws { }
        @Test func deleteGoogleForm() async throws { }
        @Test func deleteAuthBoard() async throws {
            
        }
        @Test func createProjectBoard() async throws { }
        @Test func createProfileBoard() async throws { }
        @Test func setIsUserSignedIn() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            try await #require(budClientRef.isUserSignedIn == false)
            
            // when
            await googleFormRef.signIn()
            
            // then
            await #expect(budClientRef.isUserSignedIn == true)
        }
    }
}


// MARK: Helphers
private func getGoogleForm(_ budClientRef: BudClient) async -> GoogleForm {
    await budClientRef.setUp()
    
    let authBoard = await budClientRef.authBoard!
    let authBoardRef = await AuthBoardManager.get(authBoard)!
    
    await authBoardRef.setUpForms()
    
    let googleForm = await authBoardRef.googleForm!
    let googleFormRef = await GoogleFormManager.get(googleForm)!
    
    return googleFormRef
}
