//
//  AccountHubMockTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Testing
import Foundation
import Values
@testable import BudServerMock


// MARK: Tests
@Suite("AccountHubMock")
struct AccountHubMockTests {
    // MARK: state
    struct IsExist {
        let accountHubRef: AccountHubMock
        init() async {
            self.accountHubRef = await AccountHubMock()
        }
        @Test func whenAccountIsNotExistThenFalse() async throws {
            // given
            let testEmail = Email.random().value
            let testPasssword = UUID().uuidString
            
            // when
            let isExist = await accountHubRef.isExist(email: testEmail,
                                                      password: testPasssword)
            
            // then
            #expect(isExist == false)
        }
        @Test func whenAccountIsExistThenTrue() async throws {
            // given
            let testEmail = Email.random().value
            let testPasssword = UUID().uuidString
            let accountRef = await AccountMock(email: testEmail,
                                           password: testPasssword)
            let _ = await Server.run {
                accountHubRef.accounts.insert(accountRef.id)
            }
            
            // when
            let isExist = await accountHubRef.isExist(email: testEmail,
                                                      password: testPasssword)
            
            // then
            #expect(isExist == true)
        }
    }
    
    struct GetUserIdByEmail {
        let accountHubRef: AccountHubMock
        init() async {
            self.accountHubRef = await AccountHubMock()
        }
        @Test func whenAccountIsExist() async throws {
            // given
            let testEmail = Email.random().value
            let testPasssword = UUID().uuidString
            let accountRef = await AccountMock(email: testEmail,
                                           password: testPasssword)
            let _ = await Server.run {
                accountHubRef.accounts.insert(accountRef.id)
            }
            
            // when
            let user = try await accountHubRef.getUser(email: testEmail,
                                                       password: testPasssword)
            
            // then
            #expect(user == accountRef.user)
        }
        @Test func whenUserNotFound() async throws {
            // given
            let testEmail = Email.random().value
            let testPasssword = UUID().uuidString
            
            // when
            await #expect(throws: AccountHubMock.Error.userNotFound) {
                let _ = try await accountHubRef.getUser(email: testEmail,
                                                               password: testPasssword)
            }
        }
        @Test func whenPasswordIsWrong() async throws {
            // given
            let testEmail = Email.random().value
            let testPasssword = UUID().uuidString
            let accountRef = await AccountMock(email: testEmail,
                                           password: testPasssword)
            let _ = await Server.run {
                accountHubRef.accounts.insert(accountRef.id)
            }
            
            // when
            await #expect(throws: AccountHubMock.Error.wrongPassword) {
                let _ = try await accountHubRef.getUser(email: testEmail,
                                                          password: "wrongPassword")
            }
            
        }
    }
    
    struct GetUserIdByGoogle {
        let accountHubRef: AccountHubMock
        init() async {
            self.accountHubRef = await AccountHubMock()
        }
    }
    
    // MARK: action
    struct UpdateEmailForms {
        let accountHubRef: AccountHubMock
        init() async {
            self.accountHubRef = await AccountHubMock()
        }
        
        @Test func removeTicket() async throws {
            // given
            let ticket = CreateEmailForm()
            let _ = await Server.run {
                accountHubRef.emailTickets.insert(ticket)
            }
            
            // when
            await accountHubRef.updateEmailForms()
            
            // then
            await #expect(accountHubRef.emailTickets.contains(ticket) == false)
        }
        @Test func appendEmailRegisterForm() async throws {
            // given
            let ticket = CreateEmailForm()
            let _ = await Server.run {
                accountHubRef.emailTickets.insert(ticket)
            }
            
            // when
            await accountHubRef.updateEmailForms()
            
            // then
            await #expect(accountHubRef.emailRegisterForms[ticket] != nil)
        }
        @Test func createEmailRegisterForm() async throws {
            // given
            let ticket = CreateEmailForm()
            let _ = await Server.run {
                accountHubRef.emailTickets.insert(ticket)
            }
            
            // when
            await accountHubRef.updateEmailForms()
            
            // then
            let emailRegisterForm = try #require(await accountHubRef.emailRegisterForms[ticket])
            let manager = EmailRegisterFormMockManager.self
            await #expect(manager.isExist(emailRegisterForm) == true)
        }
    }
    
    struct UpdateGoogleForms {
        let accountHubRef: AccountHubMock
        init() async {
            self.accountHubRef = await AccountHubMock()
        }
        
        @Test func removeTicket() async throws {
            // given
            let ticket = CreateGoogleForm()
            let _ = await Server.run {
                accountHubRef.googleTickets.insert(ticket)
            }
            
            // when
            await accountHubRef.updateGoogleForms()
            
            // then
            await #expect(accountHubRef.googleTickets.contains(ticket) == false)
        }
        @Test func appendGoogleRegisterForm() async throws {
            // given
            let ticket = CreateGoogleForm()
            let _ = await Server.run {
                accountHubRef.googleTickets.insert(ticket)
            }
            
            // when
            await accountHubRef.updateGoogleForms()
            
            // then
            await #expect(accountHubRef.googleRegisterForms[ticket] != nil)
        }
        @Test func createGoogleRegisterForm() async throws {
            // given
            let ticket = CreateGoogleForm()
            let _ = await Server.run {
                accountHubRef.googleTickets.insert(ticket)
            }
            
            // when
            await accountHubRef.updateGoogleForms()
            
            // then
            let googleRegisterForm = try #require(await accountHubRef.googleRegisterForms[ticket])
            let manager = GoogleRegisterFormMockManager.self
            await #expect(manager.isExist(googleRegisterForm) == true)
        }
    }
}
