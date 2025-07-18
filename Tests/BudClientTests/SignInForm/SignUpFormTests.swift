//
//  SignUpFormTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Testing
import Values
@testable import BudClient
@testable import BudCache


// MARK: Tests
@Suite("SignUpForm")
struct SignUpFormTests {
    struct SignUp {
        let budClientRef: BudClient
        let signUpFormRef: SignUpForm
        let testEmail: String
        let testPassword: String
        init() async throws {
            self.budClientRef = await BudClient()
            self.signUpFormRef = try await getSignUpForm(budClientRef)
            self.testEmail = Email.random().value
            self.testPassword = Password.random().value
        }
        
        @Test func whenSignUpFormIsDeletedBeforeCapture() async throws  {
            // given
            try await #require(signUpFormRef.id.isExist == true)
            
            // when
            await signUpFormRef.signUp {
                await signUpFormRef.delete()
            } mutateHook: {
                
            }

            // then
            let issue = try #require(await signUpFormRef.issue as? KnownIssue)
            #expect(issue.reason == "signUpFormIsDeleted")
        }
        @Test func whenSignUpFormIsDeletedBeforeMutate() async throws {
            // given
            try await #require(signUpFormRef.id.isExist == true)
            
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            // when
            await signUpFormRef.signUp {
                
            } mutateHook: {
                await signUpFormRef.delete()
            }
            
            // then
            let issue = try #require(await signUpFormRef.issue as? KnownIssue)
            #expect(issue.reason == "signUpFormIsDeleted")
            
            await #expect(budClientRef.isUserSignedIn == false)
        }
        
        @Test func failsWhenEmailIsEmpty() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = ""
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            let issue = try #require(await signUpFormRef.issue as? KnownIssue)
            #expect(issue.reason == "emailIsEmpty")
        }
        @Test func failsWhenPasswordIsEmpty() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = Email.random().value
                signUpFormRef.password = ""
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            let issue = try #require(await signUpFormRef.issue as? KnownIssue)
            #expect(issue.reason == "passwordIsEmpty")
        }
        @Test func failsWhenPasswordCheckIsEmpty() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = Email.random().value
                signUpFormRef.password = Password.random().value
                signUpFormRef.passwordCheck = ""
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            let issue = try #require(await signUpFormRef.issue as? KnownIssue)
            #expect(issue.reason == "passsworCheckIsEmpty")
            
        }
        @Test func failsWhenPasswordsDoNotMatch() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = Email.random().value
                signUpFormRef.password = Password.random().value
                signUpFormRef.passwordCheck = Password.random().value
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            let issue = try #require(await signUpFormRef.issue as? KnownIssue)
            #expect(issue.reason == "passwordsDoNotMatch")
        }
        
        @Test func setIsUserSignedIn() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            try await #require(signUpFormRef.isIssueOccurred == false)
            await #expect(budClientRef.isUserSignedIn == true)
        }
        @Test func deleteSignUpForm() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            try await #require(signUpFormRef.isIssueOccurred == false)
            await #expect(signUpFormRef.id.isExist == false)
        }
        @Test func deleteSignInForm() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            let signInForm = signUpFormRef.tempConfig.parent
            
            // when
            await signUpFormRef.signUp()
            
            // then
            try await #require(signUpFormRef.isIssueOccurred == false)
            await #expect(signInForm.isExist == false)
        }
        @Test func deleteGoogleForm() async throws {
            // given
            let signInFormRef = try #require(await budClientRef.signInForm?.ref)
            await signInFormRef.setUpGoogleForm()
            
            let googleForm = try #require(await signInFormRef.googleForm)
            
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            try await #require(signUpFormRef.isIssueOccurred == false)
            
            await #expect(googleForm.isExist == false)
        }
        
        @Test func setSignInFormNilInBudClient() async throws {
            // given
            try await #require(budClientRef.signInForm != nil)
            
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            await #expect(budClientRef.signInForm == nil)
        }
        
        @Test func createProjectBoard() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            try await #require(budClientRef.projectBoard == nil)
            
            // when
            await signUpFormRef.signUp()
            
            // then
            try await #require(signUpFormRef.isIssueOccurred == false)
            let projectBoard = try #require(await budClientRef.projectBoard)
            
            await #expect(projectBoard.isExist == true)
        }
        @Test func createProfileBoard() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            try await #require(budClientRef.profileBoard == nil)
            
            // when
            await signUpFormRef.signUp()
            
            // then
            let profileBoard = try #require(await budClientRef.profileBoard)
            await #expect(profileBoard.isExist == true)
        }
        @Test func createCommunity() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            try await #require(budClientRef.community == nil)
            
            // when
            await signUpFormRef.signUp()
            
            // then
            let community = try #require(await budClientRef.community)
            await #expect(community.isExist == true)
        }
    }
    
    struct Remove {
        let budClientRef: BudClient
        let signUpFormRef: SignUpForm
        init() async throws {
            self.budClientRef = await BudClient()
            self.signUpFormRef = try await getSignUpForm(budClientRef)
        }
        
        @Test func whenSignUpFormIsDeletedBeforeMutate() async throws {
            // given
            try await #require(signUpFormRef.id.isExist == true)
            
            // when
            await signUpFormRef.remove {
                await signUpFormRef.delete()
            }
            
            // then
            let issue = try #require(await signUpFormRef.issue as? KnownIssue)
            #expect(issue.reason == "signUpFormIsDeleted")
            
            let signInFormRef = await signUpFormRef.tempConfig.parent.ref!
            await #expect(signInFormRef.signUpForm != nil)
        }
        
        @Test func deleteSignUpForm() async throws {
            // given
            try await #require(signUpFormRef.id.isExist == true)
            
            // when
            await signUpFormRef.remove()
            
            // then
            try await #require(signUpFormRef.issue == nil)
            await #expect(signUpFormRef.id.isExist == false)
        }
        @Test func setNilToSignUpFormInEmailForm() async throws {
            // given
            let signInForm = signUpFormRef.tempConfig.parent
            let signInFormRef = try #require(await signInForm.ref)
            
            try #require(await signInFormRef.signUpForm != nil)
            
            // when
            await signUpFormRef.remove()
            
            // then
            await #expect(signInFormRef.signUpForm == nil)
            
        }
    }
}


// MARK: Helphers
private func getSignUpForm(_ budClientRef: BudClient) async throws -> SignUpForm {
    await budClientRef.setUp()
    let signInFormRef = try #require(await budClientRef.signInForm?.ref)
    
    await signInFormRef.setUpSignUpForm()
    let signUpFormRef = try #require(await signInFormRef.signUpForm?.ref)
    return signUpFormRef
}
