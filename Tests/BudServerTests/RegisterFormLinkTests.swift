//
//  RegisterFormLinkTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Testing
import BudServer
import Tools


// MARK: Tests
@Suite("RegisterForm", .tags(.real))
struct RegisterFormTests {
    let budServerLink: BudServerLink
    let registerFormLink: RegisterFormLink
    init() async {
        self.budServerLink = BudServerLink(mode: .real)
        self.registerFormLink = await getReigsterFormLink(budServerLink)
    }
    
    @Test func createAccountByRegisterForm() async throws {
        // given
        let testEmail = Email.random().value
        let testPassword = Password.random().value
        
        try! await registerFormLink.setEmail(testEmail)
        try! await registerFormLink.setPassword(testPassword)
        
        // when
        try! await registerFormLink.submit()
        
        // then
        do {
            let accountHubLink = budServerLink.getAccountHub()
            let isExist = try await accountHubLink.isExist(email: testEmail,
                                                           password: testPassword)
            #expect(isExist == true)
        } catch(let error as AccountHubLink.Error) {
            Issue.record("\(error)")
        } catch {
            // Package 환경에서는 Keychain 접근이 불가능하기 때문에 에러가 발생
        }
    }
}


// MARK: Helphers
internal func getReigsterFormLink(_ budServerLink: BudServerLink) async -> RegisterFormLink {
    let accountHubLink = budServerLink.getAccountHub()
    
    let newTicket = AccountHubLink.Ticket()
    try! await accountHubLink.insertTicket(newTicket)
    try! await accountHubLink.generateForms()
    
    let registerFormLink = try! await accountHubLink.getRegisterForm(newTicket)!
    return registerFormLink
}
