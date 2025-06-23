//
//  AccountHubMockTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Testing
import BudServerMock
import Foundation
import Tools


// MARK: Tests
@Suite("AccountHubMock")
struct AccountHubMockTests {
    // MARK: state
    struct IsExist {
        let accountHubRef: AccountHubMock
        init() async {
            self.accountHubRef = await AccountHubMock.shared
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
            let accountRef = await Account(email: testEmail,
                                           password: testPasssword)
            let _ = await MainActor.run {
                accountHubRef.accounts.insert(accountRef.id)
            }
            
            // when
            let isExist = await accountHubRef.isExist(email: testEmail,
                                                      password: testPasssword)
            
            // then
            #expect(isExist == true)
        }
    }
    
    struct GetUserId {
        let accountHubRef: AccountHubMock
        init() async {
            self.accountHubRef = await AccountHubMock.shared
        }
        @Test func whenAccountIsExist() async throws {
            // given
            let testEmail = Email.random().value
            let testPasssword = UUID().uuidString
            let accountRef = await Account(email: testEmail,
                                           password: testPasssword)
            let _ = await MainActor.run {
                accountHubRef.accounts.insert(accountRef.id)
            }
            
            // when
            let userId = await accountHubRef.getUserId(email: testEmail,
                                                       password: testPasssword)
            
            // then
            #expect(userId == accountRef.userId)
        }
        @Test func whenAccountIsNotExist() async throws {
            // given
            let testEmail = Email.random().value
            let testPasssword = UUID().uuidString
            
            // when
            let userId = await accountHubRef.getUserId(email: testEmail,
                                                       password: testPasssword)
            
            // then
            #expect(userId == nil)
        }
    }
    
    // MARK: action
    struct GenerateForms {
        let accountHubRef: AccountHubMock
        init() async {
            self.accountHubRef = await AccountHubMock.shared
        }
        
        @Test func removeTicket() async throws {
            // given
            let ticket = AccountHubMock.Ticket()
            let _ = await MainActor.run {
                accountHubRef.tickets.insert(ticket)
            }
            
            // when
            await accountHubRef.generateForms()
            
            // then
            await #expect(accountHubRef.tickets.contains(ticket) == false)
        }
        @Test func addRegisterForm() async throws {
            // given
            let ticket = AccountHubMock.Ticket()
            let _ = await MainActor.run {
                accountHubRef.tickets.insert(ticket)
            }
            
            // when
            await accountHubRef.generateForms()
            
            // then
            await #expect(accountHubRef.registerForms[ticket] != nil)
        }
        @Test func createRegisterForm() async throws {
            // given
            let ticket = AccountHubMock.Ticket()
            let _ = await MainActor.run {
                accountHubRef.tickets.insert(ticket)
            }
            
            // when
            await accountHubRef.generateForms()
            
            // then
            let registerForm = try #require(await accountHubRef.registerForms[ticket])
            await #expect(RegisterFormMockManager.get(registerForm) != nil)
        }
    }
}

