//
//  SignInFormTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Testing
import Foundation
import Values
@testable import BudClient
@testable import BudServer
@testable import BudCache


// MARK: Tests
@Suite("SignInForm")
struct SignInFormTests {
    struct SetUpSignUpForm {
        let budClientRef: BudClient
        let signInFormRef: SignInForm
        init() async throws {
            self.budClientRef = await BudClient()
            self.signInFormRef = try await getSignInForm(budClientRef)
        }
        
        @Test func whenSignInFormIsDeleted() async throws {
            // given
            try await #require(signInFormRef.id.isExist == true)
            
            // when
            await signInFormRef.setUpSignUpForm {
                await signInFormRef.delete()
            }
            
            // then
            let issue = try #require(await signInFormRef.issue as? KnownIssue)
            #expect(issue.reason == "signInFormIsDeleted")
            
            try await #require(signInFormRef.id.isExist == false)
            await #expect(signInFormRef.signUpForm == nil)
        }
        
        @Test func setSignUpForm() async throws {
            // given
            try await #require(signInFormRef.signUpForm == nil)
            
            // when
            await signInFormRef.setUpSignUpForm()
            
            // then
            await #expect(signInFormRef.signUpForm != nil)
        }
        @Test func createSignUpForm() async throws {
            // given
            try await #require(signInFormRef.signUpForm == nil)
            
            // when
            await signInFormRef.setUpSignUpForm()
            
            // then
            let signUpForm = try #require(await signInFormRef.signUpForm)
            await #expect(signUpForm.isExist == true)
        }
        @Test func whenRegisterFormAlreadyExists() async throws {
            // given
            try await #require(signInFormRef.signUpForm == nil)
            
            await signInFormRef.setUpSignUpForm()
            let signUpForm = try #require(await signInFormRef.signUpForm)
            
            // when
            await signInFormRef.setUpSignUpForm()
            
            // then
            await #expect(signInFormRef.signUpForm == signUpForm)
        }
    }
    
    struct SetUpGoogleForm {
        let budClientRef: BudClient
        let signInFormRef: SignInForm
        init() async throws {
            self.budClientRef = await BudClient()
            self.signInFormRef = try await getSignInForm(budClientRef)
        }
        
        @Test func whenSignInFormIsDeleted() async throws {
            // given
            try await #require(signInFormRef.id.isExist == true)
            
            // when
            await signInFormRef.setUpGoogleForm {
                await signInFormRef.delete()
            }
            
            // then
            let issue = try #require(await signInFormRef.issue as? KnownIssue)
            #expect(issue.reason == "signInFormIsDeleted")
        }
        
        @Test func setGoogleForm() async throws {
            // given
            try await #require(signInFormRef.googleForm == nil)
            
            // when
            await signInFormRef.setUpGoogleForm()
            
            // then
            await #expect(signInFormRef.googleForm != nil)
        }
        @Test func createGoogleForm() async throws {
            // given
            try await #require(signInFormRef.googleForm == nil)
            
            // when
            await signInFormRef.setUpGoogleForm()
            
            // then
            let googleForm = try #require(await signInFormRef.googleForm)
            await #expect(googleForm.isExist == true)
        }
    }
    
    struct SignInByCache {
        let budClientRef: BudClient
        let signInFormRef: SignInForm
        init() async throws {
            self.budClientRef = await BudClient()
            self.signInFormRef = try await getSignInForm(budClientRef)
            
            await setUserIdInBudCache(budClientRef: budClientRef)
        }
        
        @Test func whenSignInFormIsDeletedBeforeCapture() async throws {
            // given
            try await #require(signInFormRef.id.isExist == true)
            
            // when
            await signInFormRef.signInByCache {
                await signInFormRef.delete()
            } mutateHook: {
                
            }

            // then
            let issue = try #require(await signInFormRef.issue as? KnownIssue)
            #expect(issue.reason == "signInFormIsDeleted")
            
            await #expect(budClientRef.isUserSignedIn == false)
        }
        @Test func whenSignInFormIsDeletedBeforeMutate() async throws {
            // given
            try await #require(signInFormRef.id.isExist == true)
            
            // when
            await signInFormRef.signInByCache {
                
            } mutateHook: {
                await signInFormRef.delete()
            }
            
            // then
            let issue = try #require(await signInFormRef.issue as? KnownIssue)
            #expect(issue.reason == "signInFormIsDeleted")
            
            await #expect(budClientRef.isUserSignedIn == false)
        }
        
        @Test func signInWithOutEmailAndPassword() async throws {
            // given
            await MainActor.run {
                signInFormRef.email = ""
                signInFormRef.password = ""
            }
            
            try await #require(signInFormRef.isIssueOccurred == false)
            
            // when
            await signInFormRef.signInByCache()
            
            // then
            await #expect(signInFormRef.issue == nil)
        }
        
        @Test func setNilSignInFormInBudCliet() async throws {
            // when
            await signInFormRef.signInByCache()
            
            // then
            await #expect(signInFormRef.issue == nil)
            try await #require(signInFormRef.isIssueOccurred == false)
            
            await #expect(budClientRef.signInForm == nil)
        }
        @Test func deleteEmailForm() async throws {
            // when
            await signInFormRef.signInByCache()
            
            // then
            try await #require(signInFormRef.isIssueOccurred == false)
            
            await #expect(signInFormRef.id.isExist == false)
        }
        @Test func deleteSignUpForm() async throws {
            // given
            await signInFormRef.setUpSignUpForm()
            let signUpForm = try #require(await signInFormRef.signUpForm)
            try await #require(signUpForm.isExist == true)

            // when
            await signInFormRef.signInByCache()
            
            // then
            await #expect(signUpForm.isExist == false)
        }
        @Test func deleteSifnInForm() async throws {
            // given
            let signInForm = try #require(await budClientRef.signInForm)
            
            // when
            await signInFormRef.signInByCache()
            
            // then
            await #expect(signInForm.isExist == false)
        }
        @Test func createProjectBoard() async throws {
            // when
            await signInFormRef.signInByCache()
            
            // then
            let projectBoard = try #require(await budClientRef.projectBoard)
            await #expect(projectBoard.isExist == true)
        }
        @Test func createProfileBoard() async throws {
            // when
            await signInFormRef.signInByCache()
            
            // then
            let profileBoard = try #require(await budClientRef.profileBoard)
            await #expect(profileBoard.isExist == true)
        }
        @Test func createCommunity() async throws {
            // when
            await signInFormRef.signInByCache()
            
            // then
            let community = try #require(await budClientRef.community)
            await #expect(community.isExist == true)
        }
        @Test func setIsUserSignedIn() async throws {
            // when
            await signInFormRef.signInByCache()
            
            // then
            try await #require(signInFormRef.isIssueOccurred == false)
            
            await #expect(budClientRef.isUserSignedIn == true)
        }
        
        @Test func deleteGoogleForm() async throws {
            // given
            await signInFormRef.setUpGoogleForm()
            
            let googleForm = try #require(await signInFormRef.googleForm)
            try await #require(googleForm.isExist == true)
            
            // when
            await signInFormRef.signInByCache()
            
            // then
            try await #require(signInFormRef.isIssueOccurred == false)
            await #expect(googleForm.isExist == false)
        }
        
        @Test func whenEmailCredentialIsMissingAtBudCache() async throws {
            // given
            let newBudClientRef = await BudClient()
            let signInFormRef = try await getSignInForm(newBudClientRef)
            
            // when
            await signInFormRef.signInByCache()
            
            // then
            let issue = try #require(await signInFormRef.issue as? KnownIssue)
            #expect(issue.reason == "userIsNilInCache")
        }
    }
    
    struct SignIn {
        let budClientRef: BudClient
        let signInFormRef: SignInForm
        let validEmail: String
        let validPassword: String
        init() async throws {
            self.budClientRef = await BudClient()
            self.signInFormRef = try await getSignInForm(budClientRef)
            
            self.validEmail = Email.random().value
            self.validPassword = Password.random().value
            
            await register(budClientRef: budClientRef,
                           email: validEmail,
                           password: validPassword)
        }
        
        @Test func whenSignInFormIsDeletedBeforeCapture() async throws {
            // given
            try await #require(signInFormRef.id.isExist == true)
            
            // when
            await signInFormRef.signIn {
                await signInFormRef.delete()
            } mutateHook: {
                
            }

            // then
            let issue = try #require(await signInFormRef.issue as? KnownIssue)
            #expect(issue.reason == "signInFormIsDeleted")
            
            await #expect(budClientRef.isUserSignedIn == false)
        }
        @Test func whenSignInFormIsDeletedBeforeMutate() async throws {
            // given
            try await #require(signInFormRef.id.isExist == true)
            
            await MainActor.run {
                signInFormRef.email = validEmail
                signInFormRef.password = validPassword
            }
            
            // when
            await signInFormRef.signIn {
                
            } mutateHook: {
                await signInFormRef.delete()
            }
            
            // then
            let issue = try #require(await signInFormRef.issue as? KnownIssue)
            #expect(issue.reason == "signInFormIsDeleted")
            
            await #expect(budClientRef.isUserSignedIn == false)
        }
        
        @Test func whenEmailIsEmpty() async throws {
            // given
            await MainActor.run {
                signInFormRef.email = ""
            }
            
            // when
            await signInFormRef.signIn()
            
            // then
            let issue = try #require(await signInFormRef.issue as? KnownIssue)
            #expect(issue.reason == "emailIsEmpty")
        }
        @Test func whenPasswordIsEmpty() async throws {
            await MainActor.run {
                signInFormRef.email = validEmail
                signInFormRef.password = ""
            }
            
            // when
            await signInFormRef.signIn()
            
            // then
            let issue = try #require(await signInFormRef.issue as? KnownIssue)
            #expect(issue.reason == "passwordIsEmpty")
        }
        @Test func whenUserNotFound() async throws {
            // given
            await MainActor.run {
                signInFormRef.email = Email.random().value
                signInFormRef.password = Password.random().value
            }
            
            // when
            await signInFormRef.signIn()
            
            // then
            let issue = try #require(await signInFormRef.issue as? KnownIssue)
            #expect(issue.reason == "userNotFound")
        }
        @Test func whenPasswordIsWrong() async throws {
            // given
            await MainActor.run {
                signInFormRef.email = validEmail
                signInFormRef.password = Password.random().value
            }
            
            // when
            await signInFormRef.signIn()
            
            // then
            let issue = try #require(await signInFormRef.issue as? KnownIssue)
            #expect(issue.reason == "wrongPassword")
        }
        
        @Test func setNilSignInFormInBudClient() async throws {
            // given
            try await #require(budClientRef.signInForm != nil)
            
            await MainActor.run {
                signInFormRef.email = validEmail
                signInFormRef.password = validPassword
            }
            
            // when
            await signInFormRef.signIn()
            
            // then
            try await #require(signInFormRef.isIssueOccurred == false)
            await #expect(budClientRef.signInForm == nil)
        }
        
        @Test func deleteEmailForm() async throws {
            // given
            await MainActor.run {
                signInFormRef.email = validEmail
                signInFormRef.password = validPassword
            }
            
            // when
            await signInFormRef.signIn()
            
            // then
            try await #require(signInFormRef.isIssueOccurred == false)
            
            await #expect(signInFormRef.id.isExist == false)
        }
        @Test func deleteSignUpForm() async throws {
            // given
            await signInFormRef.setUpSignUpForm()
            let signUpForm = try #require(await signInFormRef.signUpForm)
            try await #require(signUpForm.isExist == true)
            
            // given
            await MainActor.run {
                signInFormRef.email = validEmail
                signInFormRef.password = validPassword
            }
            
            // when
            await signInFormRef.signIn()
            
            // then
            await #expect(signUpForm.isExist == false)
        }
        @Test func deleteGoogleForm() async throws {
            // given
            await signInFormRef.setUpGoogleForm()
            
            let googleForm = try #require(await signInFormRef.googleForm)
            try await #require(googleForm.isExist == true)
            
            await MainActor.run {
                signInFormRef.email = validEmail
                signInFormRef.password = validPassword
            }
            
            // when
            await signInFormRef.signIn()
            
            // then
            try await #require(signInFormRef.isIssueOccurred == false)
            
            await #expect(googleForm.isExist == false)
        }
        @Test func deleteSignInForm() async throws {
            // given
            await MainActor.run {
                signInFormRef.email = validEmail
                signInFormRef.password = validPassword
            }
            
            let signInForm = try #require(await budClientRef.signInForm)
            
            // when
            await signInFormRef.signIn()
            
            // then
            await #expect(signInForm.isExist == false)
        }
        @Test func createProjectBoard() async throws {
            // given
            await MainActor.run {
                signInFormRef.email = validEmail
                signInFormRef.password = validPassword
            }
            
            // when
            await signInFormRef.signIn()
            
            // then
            let projectBoard = try #require(await budClientRef.projectBoard)
            await #expect(projectBoard.isExist == true)
        }
        @Test func createProfileBoard() async throws {
            // given
            await MainActor.run {
                signInFormRef.email = validEmail
                signInFormRef.password = validPassword
            }
            
            // when
            await signInFormRef.signIn()
            
            // then
            let profileBoard = try #require(await budClientRef.profileBoard)
            await #expect(profileBoard.isExist == true)
        }
        @Test func createCommunity() async throws {
            // given
            await MainActor.run {
                signInFormRef.email = validEmail
                signInFormRef.password = validPassword
            }
            
            // when
            await signInFormRef.signIn()
            
            // then
            let community = try #require(await budClientRef.community)
            await #expect(community.isExist == true)
        }
        @Test func setIsUserSignedIn() async throws {
            // given
            await MainActor.run {
                signInFormRef.email = validEmail
                signInFormRef.password = validPassword
            }
            
            // when
            await signInFormRef.signIn()
            
            // then
            try await #require(signInFormRef.isIssueOccurred == false)
            
            await #expect(budClientRef.isUserSignedIn == true)
        }
    }
}


// MARK: Helphers
internal func getSignInForm(_ budClientRef: BudClient) async throws -> SignInForm {
    await budClientRef.setUp()
    
    let signInFormRef = try #require(await budClientRef.signInForm?.ref)
    return signInFormRef
}
private func register(budClientRef: BudClient, email: String, password: String) async {
    await budClientRef.setUp()
    
    let budServerRef = await budClientRef.signInForm!.ref!.tempConfig.budServer.ref!
    let accountHubRef = await budServerRef.accountHub.ref!
    
    let emailRegisterFormRef = await accountHubRef.emailRegisterFormType
        .init(email: email, password: password)
    
    await emailRegisterFormRef.submit()
}
private func setUserIdInBudCache(budClientRef: BudClient) async {
    // email & password
    let testEmail = Email.random().value
    let testPassword = Password.random().value
    
    // register
    await budClientRef.setUp()
    
    let budServerRef = await budClientRef.signInForm!.ref!.tempConfig.budServer.ref!
    let accountHubRef = await budServerRef.accountHub.ref!
    
    let emailRegisterFormRef = await accountHubRef.emailRegisterFormType
        .init(email: testEmail, password: testPassword)
    
    await emailRegisterFormRef.submit()
    
    // getUser
    let emailAuthFormRef = await accountHubRef.emailAuthFormType
        .init(email: testEmail, password: testPassword)
    await emailAuthFormRef.submit()
    
    let result = await emailAuthFormRef.result!
    
    guard case .success(let user) = result else {
        return
    }
    
    
    // setUser
    let budCacheRef = await budClientRef.signInForm!.ref!.tempConfig.budCache.ref!
    await budCacheRef.setUser(user)
}

