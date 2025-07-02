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
        let emailRegisterFormRef: EmailRegisterFormMock
        init() async throws {
            self.emailRegisterFormRef = await getRegisterFormMock()
        }
        
        @Test func appendAccountInAccountHub() async throws {
            // given
            let testEmail = "test@test.com"
            let testPassword = "123456"
            await Server.run {
                emailRegisterFormRef.email = testEmail
                emailRegisterFormRef.password = testPassword
            }
            
            // when
            await emailRegisterFormRef.submit()
            
            // then
            await #expect(AccountHubMock.shared.isExist(email: testEmail,
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
        let registerFormRef: EmailRegisterFormMock
        init() async throws {
            self.registerFormRef = await getRegisterFormMock()
        }
        @Test func deleteEmailRegisterForm() async throws {
            // given
            try await #require(registerFormRef.id.isExist == true)
            
            // when
            await registerFormRef.remove()
            
            // then
            await #expect(registerFormRef.id.isExist == false)
        }
        @Test func removeInAccountHub() async throws {
            // given
            let form = await AccountHubMock.shared.emailRegisterForms.values
            #expect(form.contains(registerFormRef.id) == true)
            
            // when
            await registerFormRef.remove()
            
            // then
            let updatedForms = await AccountHubMock.shared.emailRegisterForms.values
            #expect(updatedForms.contains(registerFormRef.id) == false)
        }
    }
}


// MARK: Helphers
func getRegisterFormMock() async -> EmailRegisterFormMock {
    let accountHubRef = await AccountHubMock.shared
    let newTicket = AccountHubMock.Ticket()
    
    return await Server.run {
        accountHubRef.emailTickets.insert(newTicket)
        accountHubRef.updateEmailForms()
        
        let emailRegisterForm = accountHubRef.emailRegisterForms[newTicket]!
        return emailRegisterForm.ref!
    }
}
