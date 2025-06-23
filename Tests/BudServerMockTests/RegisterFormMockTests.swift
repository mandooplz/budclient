//
//  RegisterFormMockTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import BudServerMock
import Testing
import Foundation


// MARK: Tests
@Suite("RegisterFormMock")
struct RegisterFormMockTests {
    struct Submit {
        let registerFormRef: RegisterFormMock
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
        @Test func deleteWhenSuccess() async throws {
            // given
            let testEmail = "test22@test.com"
            let testPassword = "123456"
            await MainActor.run {
                registerFormRef.email = testEmail
                registerFormRef.password = testPassword
            }
            
            // when
            await registerFormRef.submit()
            
            // then
            await #expect(RegisterFormMockManager.get(registerFormRef.id) == nil)
        }
        @Test func removeInAccountHub() async throws {
            // given
            let testEmail = "test33@test.com"
            let testPassword = "123456"
            await MainActor.run {
                registerFormRef.email = testEmail
                registerFormRef.password = testPassword
            }
            
            // when
            await registerFormRef.submit()
            
            // then
            let registerForms = await AccountHubMock.shared.registerForms.values
            #expect(registerForms.contains(registerFormRef.id) == false)
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
}


// MARK: Helphers
func getRegisterFormMock() async -> RegisterFormMock {
    let accountHubRef = await AccountHubMock.shared
    let newTicket = AccountHubMock.Ticket()
    
    return await MainActor.run {
        accountHubRef.tickets.insert(newTicket)
        accountHubRef.generateForms()
        let registerForm = accountHubRef.registerForms[newTicket]!
        return RegisterFormMockManager.get(registerForm)!
    }
}
