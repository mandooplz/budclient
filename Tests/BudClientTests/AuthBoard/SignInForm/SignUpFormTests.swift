//
//  SignUpFormTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Testing
import Tools
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
        init() async {
            self.budClientRef = await BudClient()
            self.signUpFormRef = await getSignUpForm(budClientRef)
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
            let issue = try #require(await signUpFormRef.issue)
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
            let issue = try #require(await signUpFormRef.issue)
            #expect(issue.reason == "signUpFormIsDeleted")
            
            await #expect(budClientRef.isUserSignedIn == false)
        }
        
        @Test func failsWhenEmailIsNil() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = nil
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            let issue = try #require(await signUpFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "emailIsNil")
        }
        @Test func failsWhenPasswordIsNil() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = Email.random().value
                signUpFormRef.password = nil
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            let issue = try #require(await signUpFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "passwordIsNil")
        }
        @Test func failsWhenPasswordCheckIsNil() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = Email.random().value
                signUpFormRef.password = Password.random().value
                signUpFormRef.passwordCheck = nil
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            let issue = try #require(await signUpFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "passwordCheckIsNil")
            
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
            let issue = try #require(await signUpFormRef.issue)
            #expect(issue.isKnown == true)
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
            
            let emailForm = signUpFormRef.tempConfig.parent
            
            // when
            await signUpFormRef.signUp()
            
            // then
            try await #require(signUpFormRef.isIssueOccurred == false)
            await #expect(emailForm.isExist == false)
        }
        @Test func deleteGoogleForm() async throws {
            // given
            let authBoardRef = await budClientRef.authBoard!.ref!
            let googleForm = await authBoardRef.googleForm!
            
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
        @Test func setAuthBoard() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            await #expect(budClientRef.authBoard == nil)
        }
        @Test func deleteAuthBoad() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            let authBoard = try #require(await budClientRef.authBoard)
            
            // when
            await signUpFormRef.signUp()
            
            // then
            await #expect(authBoard.isExist == false)
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
        
        @Test func setUserIdInBudCache() async throws {
            // given
            let budCacheLink = budClientRef.budCacheLink
            try await #require(budCacheLink.getUser() == nil)
            
            // given
            try await #require(signUpFormRef.issue == nil)
            
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            await #expect(budCacheLink.getUser() != nil)
        }
    }
    
    struct Remove {
        let budClientRef: BudClient
        let signUpFormRef: SignUpForm
        init() async {
            self.budClientRef = await BudClient()
            self.signUpFormRef = await getSignUpForm(budClientRef)
        }
        
        @Test func whenSignUpFormIsDeletedBeforeMutate() async throws {
            // given
            try await #require(signUpFormRef.id.isExist == true)
            
            // when
            await signUpFormRef.remove {
                await signUpFormRef.delete()
            }
            
            // then
            let issue = try #require(await signUpFormRef.issue)
            #expect(issue.reason == "signUpFormIsDeleted")
            
            let emailFormRef = await signUpFormRef.tempConfig.parent.ref!
            await #expect(emailFormRef.signUpForm != nil)
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
            let emailForm = signUpFormRef.tempConfig.parent
            let emailFormRef = try #require(await emailForm.ref)
            
            try #require(await emailFormRef.signUpForm != nil)
            
            // when
            await signUpFormRef.remove()
            
            // then
            await #expect(emailFormRef.signUpForm == nil)
            
        }
    }
}


// MARK: Helphers
internal func getSignUpForm(_ budClientRef: BudClient) async -> SignUpForm {
    let emailForm = await getEmailForm(budClientRef)
    
    await emailForm.setUpSignUpForm()
    let signUpForm = try! #require(await emailForm.signUpForm)
    let signUpFormRef = await signUpForm.ref!
    return signUpFormRef
}
