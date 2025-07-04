//
//  SignInFormTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Testing
import Foundation
import Tools
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
            self.signInFormRef = await getEmailForm(budClientRef)
        }
        
        @Test func whenSignInFormIsDeletedBeforeMutate() async throws {
            // given
            try await #require(signInFormRef.id.isExist == true)
            
            // when
            await signInFormRef.setUpSignUpForm {
                await signInFormRef.delete()
            }
            
            // then
            let issue = try #require(await signInFormRef.issue)
            #expect(issue.reason == "deleted")
            
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
            let registerForm = try #require(await signInFormRef.signUpForm)
            
            // when
            await signInFormRef.setUpSignUpForm()
            
            // then
            await #expect(signInFormRef.signUpForm == registerForm)
        }
    }
    
    struct SignInByCache {
        let budClientRef: BudClient
        let signInFormRef: SignInForm
        init() async throws {
            self.budClientRef = await BudClient()
            self.signInFormRef = await getEmailForm(budClientRef)
            
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
            let issue = try #require(await signInFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "deleted")
            
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
            let issue = try #require(await signInFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "deleted")
            
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
        
        @Test func setNilAuthBoardInBudCliet() async throws {
            // when
            await signInFormRef.signInByCache()
            
            // then
            await #expect(signInFormRef.issue == nil)
            try await #require(signInFormRef.isIssueOccurred == false)
            await #expect(budClientRef.authBoard == nil)
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
        @Test func deleteAuthBoard() async throws {
            // given
            let authBoard = try #require(await budClientRef.authBoard)
            
            // when
            await signInFormRef.signInByCache()
            
            // then
            await #expect(authBoard.isExist == false)
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
            let authBoardRef = await signInFormRef.tempConfig.parent.ref!
            let googleForm = await authBoardRef.googleForm!
            
            // when
            await signInFormRef.signInByCache()
            
            // then
            try await #require(signInFormRef.isIssueOccurred == false)
            await #expect(googleForm.isExist == false)
        }
        
        @Test func whenEmailCredentialIsMissingAtBudCache() async throws {
            // given
            let newBudClientRef = await BudClient()
            
            let emailFormRef = await getEmailForm(newBudClientRef)
            
            // when
            await emailFormRef.signInByCache()
            
            // then
            let issue = try #require(await emailFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "userIdIsNilInCache")
        }
    }
    
    struct SignIn {
        let budClientRef: BudClient
        let signInFormRef: SignInForm
        let validEmail: String
        let validPassword: String
        init() async throws {
            self.budClientRef = await BudClient()
            self.signInFormRef = await getEmailForm(budClientRef)
            
            self.validEmail = Email.random().value
            self.validPassword = Password.random().value
            
            await register(budClientRef: budClientRef, email: validEmail, password: validPassword)
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
            let issue = try #require(await signInFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "deleted")
            
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
            let issue = try #require(await signInFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "deleted")
            
            await #expect(budClientRef.isUserSignedIn == false)
        }
        
        @Test func whenEmailIsNil() async throws {
            // given
            await MainActor.run {
                signInFormRef.email = ""
            }
            
            // when
            await signInFormRef.signIn()
            
            // then
            let issue = try #require(await signInFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "emailIsNil")
        }
        @Test func whenPasswordIsNil() async throws {
            await MainActor.run {
                signInFormRef.email = validEmail
                signInFormRef.password = ""
            }
            
            // when
            await signInFormRef.signIn()
            
            // then
            let issue = try #require(await signInFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "passwordIsNil")
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
            try await #require(signInFormRef.isIssueOccurred == true)
            let issue = await signInFormRef.issue!
            #expect(issue.isKnown == true)
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
            let issue = try #require(await signInFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "wrongPassword")
        }
        
        @Test func setNilAuthBoardInBudCliet() async throws {
            // given
            await MainActor.run {
                signInFormRef.email = validEmail
                signInFormRef.password = validPassword
            }
            
            // when
            await signInFormRef.signIn()
            
            // then
            try await #require(signInFormRef.isIssueOccurred == false)
            await #expect(budClientRef.authBoard == nil)
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
            let authBoardRef = await signInFormRef.tempConfig.parent.ref!
            let googleForm = await authBoardRef.googleForm!
            
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
        @Test func deleteAuthBoard() async throws {
            // given
            await MainActor.run {
                signInFormRef.email = validEmail
                signInFormRef.password = validPassword
            }
            
            let authBoard = try #require(await budClientRef.authBoard)
            
            // when
            await signInFormRef.signIn()
            
            // then
            await #expect(authBoard.isExist == false)
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
        
        @Test func setUserInBudCache() async throws {
            // given
            try await #require(signInFormRef.issue == nil)
            try await #require(signInFormRef.issue == nil)
            
            await MainActor.run {
                signInFormRef.email = validEmail
                signInFormRef.password = validPassword
            }
            
            await signInFormRef.signInByCache()
            try await #require(signInFormRef.issue != nil)
            
            // when
            await signInFormRef.signIn()
            
            // then
            let budCacheLink = budClientRef.budCacheLink
            await #expect(budCacheLink.getUser() != nil)
        }
    }
}


// MARK: Helphers
internal func getEmailForm(_ budClientRef: BudClient) async -> SignInForm {
    let authBoardRef = await getAuthBoard(budClientRef)
    
    await authBoardRef.setUpForms()
    let emailForm = await authBoardRef.signInForm!
    return await emailForm.ref!
}
private func register(budClientRef: BudClient, email: String, password: String) async {
    let budServerLink = await budClientRef.budServerLink!
    let accountHubLink = await budServerLink.getAccountHub()
    
    let newTicket = AccountHubLink.Ticket()
    await accountHubLink.insertEmailTicket(newTicket)
    await accountHubLink.updateEmailForms()
    
    let registerFormLink = await accountHubLink.getEmailRegisterForm(newTicket)!
    await registerFormLink.setEmail(email)
    await registerFormLink.setPassword(password)
    
    await registerFormLink.submit()
    await registerFormLink.remove()
}
private func setUserIdInBudCache(budClientRef: BudClient) async {
    // email & password
    let testEmail = Email.random().value
    let testPassword = Password.random().value
    
    // register
    let budServerRef = await BudServerMock()
    await budServerRef.setUp()
    
    let budServerLink = try! await BudServerLink(mode: .test(budServerRef))
    let accountHubLink = await budServerLink.getAccountHub()
    
    let newTicket = AccountHubLink.Ticket()
    await accountHubLink.insertEmailTicket(newTicket)
    await accountHubLink.updateEmailForms()
    
    let emailRegisterFormLink = await accountHubLink.getEmailRegisterForm(newTicket)!
    await emailRegisterFormLink.setEmail(testEmail)
    await emailRegisterFormLink.setPassword(testPassword)
    
    await emailRegisterFormLink.submit()
    await emailRegisterFormLink.remove()
    
    // getUserId
    let user = try! await accountHubLink.getUserId(email: testEmail, password: testPassword)
    
    
    // setUserId
    let budCacheLink = budClientRef.budCacheLink
    await budCacheLink.setUser(user)
}
