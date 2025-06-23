//
//  AccountHubMockTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Testing
import BudServerMock
import Foundation


// MARK: Tests
@Suite("AccountHubMock")
struct AccountHubMockTests {
    // MARK: state
    struct IsExist {
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
