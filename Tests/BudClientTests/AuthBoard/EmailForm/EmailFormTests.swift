//
//  EmailFormTests.swift
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
@Suite("EmailForm")
struct EmailFormTests {
    struct SetUpSignUpForm {
        let budClientRef: BudClient
        let emailFormRef: EmailForm
        init() async throws {
            self.budClientRef = await BudClient()
            self.emailFormRef = await getEmailForm(budClientRef)
        }
        
        @Test func setRegisterForm() async throws {
            // given
            try await #require(emailFormRef.signUpForm == nil)
            
            // when
            await emailFormRef.setUpSignUpForm()
            
            // then
            await #expect(emailFormRef.signUpForm != nil)
        }
        @Test func createRegisterForm() async throws {
            // given
            try await #require(emailFormRef.signUpForm == nil)
            
            // when
            await emailFormRef.setUpSignUpForm()
            
            // then
            let registerForm = try #require(await emailFormRef.signUpForm)
            await #expect(SignUpFormManager.get(registerForm) != nil)
        }
        @Test func whenRegisterFormAlreadyExists() async throws {
            // given
            try await #require(emailFormRef.signUpForm == nil)
            
            await emailFormRef.setUpSignUpForm()
            let registerForm = try #require(await emailFormRef.signUpForm)
            
            // when
            await emailFormRef.setUpSignUpForm()
            
            // then
            await #expect(emailFormRef.signUpForm == registerForm)
        }
    }
    
    struct SignInByCache {
        let budClientRef: BudClient
        let emailFormRef: EmailForm
        init() async throws {
            self.budClientRef = await BudClient()
            self.emailFormRef = await getEmailForm(budClientRef)
            
            await setEmailCredentialInBudCache(budClientRef: budClientRef)
        }
        
        @Test func signInWithOutEmailAndPassword() async throws {
            // given
            await MainActor.run {
                emailFormRef.email = ""
                emailFormRef.password = ""
            }
            
            try await #require(emailFormRef.isIssueOccurred == false)
            
            // when
            await emailFormRef.signInByCache()
            
            // then
            await #expect(emailFormRef.issue == nil)
        }
        
        @Test func setNilAuthBoardInBudCliet() async throws {
            // when
            await emailFormRef.signInByCache()
            
            // then
            await #expect(emailFormRef.issue == nil)
            try await #require(emailFormRef.isIssueOccurred == false)
            await #expect(budClientRef.authBoard == nil)
        }
        @Test func deleteEmailFormWhenSuccess() async throws {
            // when
            await emailFormRef.signInByCache()
            
            // then
            try await #require(emailFormRef.isIssueOccurred == false)
            
            await #expect(EmailFormManager.get(emailFormRef.id) == nil)
        }
        @Test func deleteSignUpFormWhenSuccess() async throws {
            // given
            await emailFormRef.setUpSignUpForm()
            let signUpForm = try #require(await emailFormRef.signUpForm)
            try await #require(SignUpFormManager.get(signUpForm) != nil)

            // when
            await emailFormRef.signInByCache()
            
            // then
            await #expect(SignUpFormManager.get(signUpForm) == nil)
        }
        @Test func deleteAuthBoardWhenSuccess() async throws {
            // given
            let authBoard = try #require(await budClientRef.authBoard)
            
            // when
            await emailFormRef.signInByCache()
            
            // then
            await #expect(AuthBoardManager.get(authBoard) == nil)
        }
        @Test func createProjectBoardWhenSuccess() async throws {
            // when
            await emailFormRef.signInByCache()
            
            // then
            let projectBoard = try #require(await budClientRef.projectBoard)
            await #expect(ProjectBoardManager.get(projectBoard) != nil)
        }
        @Test func createProfileBoardWhenSuccess() async throws {
            // when
            await emailFormRef.signInByCache()
            
            // then
            let profileBoard = try #require(await budClientRef.profileBoard)
            await #expect(ProfileBoardManager.get(profileBoard) != nil)
        }
        @Test func setIsUserSignedInWhenSuccess() async throws {
            // when
            await emailFormRef.signInByCache()
            
            // then
            try await #require(emailFormRef.isIssueOccurred == false)
            
            await #expect(budClientRef.isUserSignedIn == true)
        }
        
        @Test func deleteGoogleFormWhenSuccess() async throws {
            // given
            let authBoardRef = await AuthBoardManager.get(emailFormRef.authBoard)!
            let googleForm = await authBoardRef.googleForm!
            
            // when
            await emailFormRef.signInByCache()
            
            // then
            try await #require(emailFormRef.isIssueOccurred == false)
            await #expect(GoogleFormManager.get(googleForm) == nil)
        }
        
        // emailCredential이 존재하지 않는 경우 실패할 때 테스트 작성
        @Test func whenEmailCredentialIsMissing() async throws {
            // given
            let newBudClientRef = await BudClient()
            
            let emailFormRef = await getEmailForm(newBudClientRef)
            
            // when
            await emailFormRef.signInByCache()
            
            // then
            let issueForDebug = try #require(await emailFormRef.issueForDebug)
            #expect(issueForDebug.isKnown == true)
            #expect(issueForDebug.reason == "userIdIsNilInCache")
        }
    }
    
    struct SignIn {
        let budClientRef: BudClient
        let emailFormRef: EmailForm
        let validEmail: String
        let validPassword: String
        init() async throws {
            self.budClientRef = await BudClient()
            self.emailFormRef = await getEmailForm(budClientRef)
            
            self.validEmail = Email.random().value
            self.validPassword = Password.random().value
            
            await register(email: validEmail, password: validPassword)
        }
        
        @Test func whenEmailIsNil() async throws {
            // given
            await MainActor.run {
                emailFormRef.email = ""
            }
            
            // when
            await emailFormRef.signIn()
            
            // then
            let issue = try #require(await emailFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "emailIsNil")
        }
        @Test func whenPasswordIsNil() async throws {
            await MainActor.run {
                emailFormRef.email = validEmail
                emailFormRef.password = ""
            }
            
            // when
            await emailFormRef.signIn()
            
            // then
            let issue = try #require(await emailFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "passwordIsNil")
        }
        @Test func whenUserNotFound() async throws {
            // given
            await MainActor.run {
                emailFormRef.email = Email.random().value
                emailFormRef.password = Password.random().value
            }
            
            // when
            await emailFormRef.signIn()
            
            // then
            try await #require(emailFormRef.isIssueOccurred == true)
            let issue = await emailFormRef.issue!
            #expect(issue.isKnown == true)
            #expect(issue.reason == "userNotFound")
        }
        @Test func whenPasswordIsWrong() async throws {
            // given
            await MainActor.run {
                emailFormRef.email = validEmail
                emailFormRef.password = Password.random().value
            }
            
            // when
            await emailFormRef.signIn()
            
            // then
            let issue = try #require(await emailFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "wrongPassword")
        }
        
        @Test func setNilAuthBoardInBudCliet() async throws {
            // given
            await MainActor.run {
                emailFormRef.email = validEmail
                emailFormRef.password = validPassword
            }
            
            // when
            await emailFormRef.signIn()
            
            // then
            try await #require(emailFormRef.isIssueOccurred == false)
            await #expect(budClientRef.authBoard == nil)
        }
        
        @Test func deleteEmailFormWhenSuccess() async throws {
            // given
            await MainActor.run {
                emailFormRef.email = validEmail
                emailFormRef.password = validPassword
            }
            
            // when
            await emailFormRef.signIn()
            
            // then
            try await #require(emailFormRef.isIssueOccurred == false)
            
            await #expect(EmailFormManager.get(emailFormRef.id) == nil)
        }
        @Test func deleteSignUpFormWhenSuccess() async throws {
            // given
            await emailFormRef.setUpSignUpForm()
            let signUpForm = try #require(await emailFormRef.signUpForm)
            try await #require(SignUpFormManager.get(signUpForm) != nil)
            
            // given
            await MainActor.run {
                emailFormRef.email = validEmail
                emailFormRef.password = validPassword
            }
            
            // when
            await emailFormRef.signIn()
            
            // then
            await #expect(SignUpFormManager.get(signUpForm) == nil)
        }
        @Test func deleteGoogleFormWhenSuccess() async throws {
            // given
            let authBoardRef = await AuthBoardManager.get(emailFormRef.authBoard)!
            let googleForm = await authBoardRef.googleForm!
            
            await MainActor.run {
                emailFormRef.email = validEmail
                emailFormRef.password = validPassword
            }
            
            // when
            await emailFormRef.signIn()
            
            // then
            try await #require(emailFormRef.isIssueOccurred == false)
            
            await #expect(GoogleFormManager.get(googleForm) == nil)
        }
        @Test func deleteAuthBoardWhenSuccess() async throws {
            // given
            await MainActor.run {
                emailFormRef.email = validEmail
                emailFormRef.password = validPassword
            }
            
            let authBoard = try #require(await budClientRef.authBoard)
            
            // when
            await emailFormRef.signIn()
            
            // then
            await #expect(AuthBoardManager.get(authBoard) == nil)
        }
        @Test func createProjectBoardWhenSuccess() async throws {
            // given
            await MainActor.run {
                emailFormRef.email = validEmail
                emailFormRef.password = validPassword
            }
            
            // when
            await emailFormRef.signIn()
            
            // then
            let projectBoard = try #require(await budClientRef.projectBoard)
            await #expect(ProjectBoardManager.get(projectBoard) != nil)
        }
        @Test func createProfileBoardWhenSuccess() async throws {
            // given
            await MainActor.run {
                emailFormRef.email = validEmail
                emailFormRef.password = validPassword
            }
            
            // when
            await emailFormRef.signIn()
            
            // then
            let profileBoard = try #require(await budClientRef.profileBoard)
            await #expect(ProfileBoardManager.get(profileBoard) != nil)
        }
        @Test func setIsUserSignedInWhenSuccess() async throws {
            // given
            await MainActor.run {
                emailFormRef.email = validEmail
                emailFormRef.password = validPassword
            }
            
            // when
            await emailFormRef.signIn()
            
            // then
            try await #require(emailFormRef.isIssueOccurred == false)
            
            await #expect(budClientRef.isUserSignedIn == true)
        }
        
        @Test func saveCredentialToBudCacheWhenSuccess() async throws {
            // given
            try await #require(emailFormRef.issue == nil)
            try await #require(emailFormRef.issueForDebug == nil)
            
            await MainActor.run {
                emailFormRef.email = validEmail
                emailFormRef.password = validPassword
            }
            
            await emailFormRef.signInByCache()
            try await #require(emailFormRef.issueForDebug != nil)
            
            // when
            await emailFormRef.signIn()
            
            // then
            let budCacheLink = BudCacheLink(mode: budClientRef.mode,
                                            budCacheMockRef: budClientRef.budCacheMockRef)
            await #expect(budCacheLink.isEmailCredentialSet() == true)
        }
    }
}


// MARK: Helphers
internal func getEmailForm(_ budClientRef: BudClient) async -> EmailForm {
    let authBoardRef = await getAuthBoard(budClientRef)
    
    await authBoardRef.setUpForms()
    let emailForm = await authBoardRef.emailForm!
    let emailFormRef = await EmailFormManager.get(emailForm)!
    return emailFormRef
}
private func register(email: String, password: String) async {
    let budServerLink = try! BudServerLink(mode: .test)
    let accountHubLink = budServerLink.getAccountHub()
    
    let newTicket = AccountHubLink.Ticket()
    try! await accountHubLink.insertEmailTicket(newTicket)
    try! await accountHubLink.updateEmailForms()
    
    let registerFormLink = try! await accountHubLink.getEmailRegisterForm(newTicket)!
    try! await registerFormLink.setEmail(email)
    try! await registerFormLink.setPassword(password)
    
    try! await registerFormLink.submit()
    try! await registerFormLink.remove()
}
private func setEmailCredentialInBudCache(budClientRef: BudClient) async {
    let mode = budClientRef.mode
    let budCacheMockRef = budClientRef.budCacheMockRef
    
    // email & password
    let testEmail = Email.random().value
    let testPassword = Password.random().value
    
    // register
    let budServerLink = try! BudServerLink(mode: .test)
    let accountHubLink = budServerLink.getAccountHub()
    
    let newTicket = AccountHubLink.Ticket()
    try! await accountHubLink.insertEmailTicket(newTicket)
    try! await accountHubLink.updateEmailForms()
    
    let registerFormLink = try! await accountHubLink.getEmailRegisterForm(newTicket)!
    try! await registerFormLink.setEmail(testEmail)
    try! await registerFormLink.setPassword(testPassword)
    
    try! await registerFormLink.submit()
    try! await registerFormLink.remove()
    
    
    // setEmailCredential
    let budCacheLink = BudCacheLink(mode: mode, budCacheMockRef: budCacheMockRef)
    
    try! await budCacheLink.setEmailCredential(.init(email: testEmail,
                                                    password: testPassword))
}
