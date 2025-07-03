//
//  EmailForm.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Testing
import Foundation
import Tools
@testable import BudServer


// MARK: Tests
@Suite("EmailRegisterFormMock")
struct EmailRegisterFormMockTests {
    struct Submit {
        let budServerRef: BudServerMock
        let emailRegisterFormRef: EmailRegisterFormMock
        init() async throws {
            self.budServerRef = await BudServerMock()
            self.emailRegisterFormRef = await getRegisterFormMock(budServerRef)
        }
        
        @Test func appendAccountInAccountHub() async throws {
            // given
            let accountHubRef = await budServerRef.accountHubRef!
            
            let testEmail = "test@test.com"
            let testPassword = "123456"
            await Server.run {
                emailRegisterFormRef.email = testEmail
                emailRegisterFormRef.password = testPassword
            }
            
            // when
            await emailRegisterFormRef.submit()
            
            // then
            await #expect(accountHubRef.isExist(email: testEmail,
                                                        password: testPassword) == true)
        }
        
        @Test func whenEmailIsNil() async throws {
            // given
            await Server.run {
                emailRegisterFormRef.email = nil
                emailRegisterFormRef.password = nil
            }
            
            // when
            await emailRegisterFormRef.submit()
            
            // then
            let issue = try #require(await emailRegisterFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "emailIsNil")
        }
        @Test func whenPasswordIsNil() async throws {
            // given
            let testEmail = "test@test.com"
            await Server.run {
                emailRegisterFormRef.email = testEmail
                emailRegisterFormRef.password = nil
            }
            
            // when
            await emailRegisterFormRef.submit()
            
            // then
            let issue = try #require(await emailRegisterFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "passwordIsNil")
        }
    }
    
    struct Remove {
        let budServerRef: BudServerMock
        let emailRegisterFormRef: EmailRegisterFormMock
        init() async throws {
            self.budServerRef = await BudServerMock()
            self.emailRegisterFormRef = await getRegisterFormMock(budServerRef)
        }
        @Test func deleteEmailRegisterForm() async throws {
            // given
            try await #require(emailRegisterFormRef.id.isExist == true)
            
            // when
            await emailRegisterFormRef.remove()
            
            // then
            await #expect(emailRegisterFormRef.id.isExist == false)
        }
        @Test func removeInAccountHub() async throws {
            // given
            let accountHubRef = await budServerRef.accountHubRef!
            
            let form = await accountHubRef.emailRegisterForms.values
            #expect(form.contains(emailRegisterFormRef.id) == true)
            
            // when
            await emailRegisterFormRef.remove()
            
            // then
            let updatedForms = await accountHubRef.emailRegisterForms.values
            #expect(updatedForms.contains(emailRegisterFormRef.id) == false)
        }
    }
}


// MARK: Helphers
func getRegisterFormMock(_ budServerMockRef: BudServerMock) async -> EmailRegisterFormMock {
    await budServerMockRef.setUp()
    
    let accountHubRef = await budServerMockRef.accountHubRef!
    let newTicket = AccountHubMock.Ticket()
    
    return await Server.run {
        accountHubRef.emailTickets.insert(newTicket)
        accountHubRef.updateEmailForms()
        
        let emailRegisterForm = accountHubRef.emailRegisterForms[newTicket]!
        return emailRegisterForm.ref!
    }
}
