//
//  CommunityTests.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Testing
import Values
@testable import BudClient


// MARK: Tests
@Suite("Community")
struct CommunityTests {
    
}



// MARK: Helphers
private func getCommunity(_ budClientRef: BudClient) async throws -> Community {
    // BudClient.setUp()
    await budClientRef.setUp()
    let signInForm = try #require(await budClientRef.signInForm)
    let signInFormRef = try #require(await signInForm.ref)
    
    // SignInForm.setUpSignUpForm()
    await signInFormRef.setUpSignUpForm()
    let signUpFormRef = try #require(await signInFormRef.signUpForm?.ref)
    
    
    // SignUpForm.signUp()
    let testEmail = Email.random().value
    let testPassword = Password.random().value
    await MainActor.run {
        signUpFormRef.email = testEmail
        signUpFormRef.password = testPassword
        signUpFormRef.passwordCheck = testPassword
    }
    
    await signUpFormRef.signUp()
    
    // Community
    let communityRef = try #require(await budClientRef.community?.ref)
    return communityRef
}
