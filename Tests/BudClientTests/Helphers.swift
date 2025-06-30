//
//  Helphers.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Testing
import Tools
import os
@testable import BudClient


// MARK: Tags
extension Tag {
    @Tag static var real: Self
}


// MARK: Logger
fileprivate let logger = Logger(subsystem: "com.ginger.budclient.test", category: "test")


// MARK: Navigator
func signIn(_ budClietRef: BudClient) async {
    await budClietRef.setUp()
    guard let authBoardRef = await budClietRef.authBoard?.ref else {
        logger.error("BudClient.setUp() failed")
        return
    }
    
    await authBoardRef.setUpForms()
    guard let signInFormRef = await authBoardRef.signInForm?.ref else {
        logger.error("AuthBoard.setUpForms() failed")
        return
    }
    
    await signInFormRef.setUpSignUpForm()
    guard let signUpFormRef = await signInFormRef.signUpForm?.ref else {
        logger.error("SignInForm.setUpSignUpForm() failed")
        return
    }
    
    let testEmail = Email.random().value
    let testPassword = Password.random().value
    await MainActor.run {
        signUpFormRef.email = testEmail
        signUpFormRef.password = testPassword
        signUpFormRef.passwordCheck = testPassword
    }
    
    await signUpFormRef.signUp()
    let isSignedIn = await MainActor.run {
        signUpFormRef.isIssueOccurred == false &&
        budClietRef.isUserSignedIn == true &&
        budClietRef.authBoard == nil &&
        budClietRef.projectBoard != nil &&
        budClietRef.profileBoard != nil
    }
    guard isSignedIn == true else {
        logger.error("SignUpForm.signUp() failed")
        return
    }
}
