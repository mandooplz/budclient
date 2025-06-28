//
//  ProfileBoardTests.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Foundation
import Testing
@testable import BudClient
import Tools


// MARK: Tests
@Suite("ProfileBoard")
struct ProfileBoardTests {
    struct SignOut {
        let budClientRef: BudClient
        let profileBoardRef: ProfileBoard
        init() async {
            self.budClientRef = await BudClient()
            self.profileBoardRef = await getProfileBoard(budClientRef)
        }
        
        @Test func setIsUserSignedInAtBudClient() async throws {
            // given
            try await #require(budClientRef.isUserSignedIn == true)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(budClientRef.isUserSignedIn == true)
        }
        
        // TODO: ProjectBoard, ProfileBoard의 하위 객체들을 정의한다면 테스트를 추가해야 함
        @Test func createAuthBoard() async throws {
            // given
            try await #require(budClientRef.authBoard == nil)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            let authBoard = try #require(await budClientRef.authBoard)
            await #expect(AuthBoardManager.get(authBoard) != nil)
        }
        @Test func deleteProjectBoard() async throws {
            // given
            let projectBoard = try #require(await budClientRef.projectBoard)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(ProjectBoardManager.get(projectBoard) == nil)
        }
        @Test func deleteProjectsInProjectBoard() async throws {
            // given
            let projectBoard = try #require(await budClientRef.projectBoard)
            let projectBoardRef = try #require(await ProjectBoardManager.get(projectBoard))
            let projects = await projectBoardRef.projects
            
            // when
            await profileBoardRef.signOut()
            
            // then
            for project in projects {
                await #expect(ProjectManager.get(project) == nil)
            }
        }
        @Test func deleteProfileBoard() async throws {
            // given
            try await #require(budClientRef.profileBoard != nil)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(budClientRef.profileBoard == nil)
            await #expect(ProfileBoardManager.get(profileBoardRef.id) == nil)
        }
    }
}


// MARK: Helphers
private func getProfileBoard(_ budClientRef: BudClient) async -> ProfileBoard {
    await budClientRef.setUp()
    
    let authBoard = await budClientRef.authBoard!
    let authBoardRef = await AuthBoardManager.get(authBoard)!
    
    await authBoardRef.setUpForms()
    let emailForm = await authBoardRef.emailForm!
    let emailFormRef = await EmailFormManager.get(emailForm)!
    
    await emailFormRef.setUpSignUpForm()
    let signUpForm = await emailFormRef.signUpForm!
    let signUpFormRef = await SignUpFormManager.get(signUpForm)!
    
    let testEmail = Email.random().value
    let testPassword = Password.random().value
    await MainActor.run {
        signUpFormRef.email = testEmail
        signUpFormRef.password = testPassword
        signUpFormRef.passwordCheck = testPassword
    }
    
    await signUpFormRef.signUp()
    try! await #require(signUpFormRef.isIssueOccurred == false)
    
    try! await #require(budClientRef.isUserSignedIn == true)
    try! await #require(budClientRef.authBoard == nil)
    try! await #require(budClientRef.projectBoard != nil)
    try! await #require(budClientRef.profileBoard != nil)
    
    let profileBoard = await budClientRef.profileBoard!
    let profileBoardRef = await ProfileBoardManager.get(profileBoard)!
    return profileBoardRef
}
