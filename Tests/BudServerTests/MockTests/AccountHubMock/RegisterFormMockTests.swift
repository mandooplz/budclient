//
//  EmailForm.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Testing
import Foundation
@testable import BudServer


// MARK: Tests
@Suite("EmailFormMockTests")
struct RegisterFormMockTests {
    struct Submit {
        let registerFormRef: EmailRegisterFormMock
        init() async throws {
            self.registerFormRef = await getRegisterFormMock()
        }
        
        @Test func appendAccountInAccountHub() async throws {
            // given
            let testEmail = "test@test.com"
            let testPassword = "123456"
            await MainActor.run {
                registerFormRef.email = testEmail
                registerFormRef.password = testPassword
            }
            
            // when
            await registerFormRef.submit()
            
            // then
            await #expect(AccountHubMock.shared.isExist(email: testEmail,
                                                        password: testPassword) == true)
        }
        
        @Test func whenEmailIsNil() async throws {
            // given
            await MainActor.run {
                registerFormRef.email = nil
                registerFormRef.password = nil
            }
            
            // when
            await registerFormRef.submit()
            
            // then
            let issue = try #require(await registerFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "emailIsNil")
        }
        @Test func whenPasswordIsNil() async throws {
            // given
            let testEmail = "test@test.com"
            await MainActor.run {
                registerFormRef.email = testEmail
                registerFormRef.password = nil
            }
            
            // when
            await registerFormRef.submit()
            
            // then
            let issue = try #require(await registerFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "passwordIsNil")
        }
    }
    
    struct Remove {
        let registerFormRef: EmailRegisterFormMock
        init() async throws {
            self.registerFormRef = await getRegisterFormMock()
        }
        @Test func deleteWhenSuccess() async throws {
            // given
            try await #require(EmailRegisterFormMockManager.get(registerFormRef.id) != nil)
            
            // when
            await registerFormRef.remove()
            
            // then
            await #expect(EmailRegisterFormMockManager.get(registerFormRef.id) == nil)
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
    
    return await MainActor.run {
        accountHubRef.emailTickets.insert(newTicket)
        accountHubRef.updateEmailForms()
        let registerForm = accountHubRef.emailRegisterForms[newTicket]!
        return EmailRegisterFormMockManager.get(registerForm)!
    }
}
