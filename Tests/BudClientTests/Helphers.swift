//
//  Helphers.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Testing
import Values
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


func createAndGetProject(_ budClientRef: BudClient) async -> ProjectEditor {
    await signIn(budClientRef)
    
    let projectBoard = await budClientRef.projectBoard!
    let projectBoardRef = await projectBoard.ref!
    
    await projectBoardRef.setUp()
    try! await #require(projectBoardRef.updater != nil)
    
    await withCheckedContinuation { continuation in
        Task {
            await projectBoardRef.setCallback {
                continuation.resume()
            }
            
            await projectBoardRef.subscribe()
            await projectBoardRef.createProject()
        }
    }
    
    try! await #require(projectBoardRef.editors.count == 1)
    
    // contunuation의 참조 제거
    await projectBoardRef.unsubscribe()
    
    // 다시 구독
    await projectBoardRef.setCallback({ })
    await projectBoardRef.subscribe()
    
    
    try! await #require(projectBoardRef.editors.count == 1)
    
    let project = await projectBoardRef.editors.first!
    return await project.ref!
}


func createAndGetSystemBoard(_ budClientRef: BudClient) async -> SystemBoard {
    let projectRef = await createAndGetProject(budClientRef)
    
    await projectRef.setUp()
    guard let systemBoardRef = await projectRef.systemBoard?.ref else {
        logger.error(": systemBoardRef is nil")
        fatalError()
    }
    
    return systemBoardRef
}



func getSystemModel(_ budClientRef: BudClient) async -> SystemModel {
    let systemBoardRef = await createAndGetSystemBoard(budClientRef)
    
    await systemBoardRef.setUp()
    
    await withCheckedContinuation { con in
        Task {
            await systemBoardRef.unsubscribe()
            await systemBoardRef.setCallback {
                con.resume()
            }
            
            await systemBoardRef.subscribe()
            await systemBoardRef.createFirstSystem()
        }
    }
    
    await systemBoardRef.unsubscribe()
    
    let systemModel = await systemBoardRef.models.first!
    return await systemModel.ref!
}
