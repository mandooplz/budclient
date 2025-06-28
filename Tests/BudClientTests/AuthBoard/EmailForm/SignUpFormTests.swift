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
        
        @Test func toggleIsConsumedWhenSuccess() async throws {
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
            await #expect(signUpFormRef.isConsumed == true)
        }
        
        @Test func setIsUserSignedInAtBudClient() async throws {
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
        @Test func setAuthBoardNilInBudClient() async throws {
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
        
        @Test func deleteSignUpFormWhenSuccess() async throws {
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
            await #expect(SignUpFormManager.get(signUpFormRef.id) == nil)
        }
        @Test func deleteEmailFormWhenSuccess() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            let emailForm = signUpFormRef.emailForm
            
            // when
            await signUpFormRef.signUp()
            
            // then
            try await #require(signUpFormRef.isIssueOccurred == false)
            await #expect(EmailFormManager.get(emailForm) == nil)
        }
        @Test func deleteGoogleFormWhenSucess() async throws {
            // given
            let authBoardRef = await AuthBoardManager.get(budClientRef.authBoard!)!
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
            
            await #expect(GoogleFormManager.get(googleForm) == nil)
        }
        @Test func deleteAuthBoadWhenSuccess() async throws {
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
            await #expect(AuthBoardManager.get(authBoard) == nil)
        }
        
        @Test func createProjectBoardWhenSuccess() async throws {
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
            let projectBoard = try #require(await budClientRef.projectBoard)
            
            await #expect(ProjectBoardManager.get(projectBoard) != nil)
        }
        @Test func createProfileBoardWhenSuccess() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            let profileBoard = try #require(await budClientRef.profileBoard)
            await #expect(ProfileBoardManager.get(profileBoard) != nil)
        }
        
        @Test func saveCredentialToBudCacheWhenSuccess() async throws {
            // given
            let budCacheLink = BudCacheLink(mode: budClientRef.mode,
                                            budCacheMockRef: budClientRef.budCacheMockRef)
            await #expect(budCacheLink.isEmailCredentialSet() == false)
            
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
            await #expect(budCacheLink.isEmailCredentialSet() == true)
        }
    }
    
    struct Remove {
        let budClientRef: BudClient
        let signUpFormRef: SignUpForm
        init() async {
            self.budClientRef = await BudClient()
            self.signUpFormRef = await getSignUpForm(budClientRef)
        }
        @Test func deleteSignUpForm() async throws {
            // given
            try await #require(SignUpFormManager.get(signUpFormRef.id) != nil)
            
            // when
            await signUpFormRef.remove()
            
            // then
            try await #require(signUpFormRef.issue == nil)
            await #expect(SignUpFormManager.get(signUpFormRef.id) == nil)
        }
        @Test func setNilToSignUpFormInEmailForm() async throws {
            // given
            let emailForm = signUpFormRef.emailForm
            let emailFormRef = try #require(await EmailFormManager.get(emailForm))
            
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
    let signUpFormRef = await SignUpFormManager.get(signUpForm)!
    return signUpFormRef
}
