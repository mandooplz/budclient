//
//  ProfileBoardTests.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Foundation
import Testing
@testable import BudClient
import Values


// MARK: Tests
@Suite("ProfileBoard")
struct ProfileBoardTests {
    struct SignOut {
        let budClientRef: BudClient
        let profileBoardRef: ProfileBoard
        init() async throws {
            self.budClientRef = await BudClient()
            self.profileBoardRef = try await getProfileBoard(budClientRef)
        }
        
        @Test func whenProfileBoardIsDeletedBeforeCapture() async throws {
            // given
            try await #require(budClientRef.profileBoard?.isExist == true)
            
            let budCacheLink = budClientRef.budCacheLink
            try await #require(budCacheLink.getUser() != nil)
            
            // when
            await profileBoardRef.signOut {
                await profileBoardRef.delete()
            } mutateHook: {
                
            }

            // then
            let issue = try #require(await profileBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "profileBoardIsDeleted")
            
            try await #require(budClientRef.profileBoard?.isExist == false)
            await #expect(budCacheLink.getUser() != nil)
        }
        @Test func whenProfileBoardIsDeletedBeforeMutate() async throws {
            // given
            try await #require(budClientRef.profileBoard?.isExist == true)
            
            let budCacheLink = budClientRef.budCacheLink
            try await #require(budCacheLink.getUser() != nil)
            
            // when
            await profileBoardRef.signOut {
                
            } mutateHook: {
                await profileBoardRef.delete()
            }

            // then
            let issue = try #require(await profileBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "profileBoardIsDeleted")
            
            try await #require(budClientRef.profileBoard?.isExist == false)
            await #expect(budClientRef.isUserSignedIn == true)
        }
        
        // TODO: 하위 객체들을 계속해서 추가해야 함
        @Test func setIsUserSignedInAtBudClient() async throws {
            // given
            try await #require(budClientRef.isUserSignedIn == true)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(budClientRef.isUserSignedIn == false)
        }
        @Test func createAuthBoard() async throws {
            // given
            try await #require(budClientRef.authBoard == nil)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            let authBoard = try #require(await budClientRef.authBoard)
            await #expect(authBoard.isExist == true)
        }
        
        @Test func deleteProjectBoard() async throws {
            // given
            let projectBoard = try #require(await budClientRef.projectBoard)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(projectBoard.isExist == false)
        }
        @Test func deleteProjectBoardUpdater() async throws {
            // given
            let projectBoardRef = try #require(await budClientRef.projectBoard?.ref)
            
            await projectBoardRef.setUpUpdater()
            try await #require(projectBoardRef.updater?.isExist == true)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(projectBoardRef.updater?.isExist == false)
        }
        @Test func deleteProjects() async throws {
            // given
            let projectBoard = try #require(await budClientRef.projectBoard)
            let projectBoardRef = try #require(await projectBoard.ref)
            
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    await projectBoardRef.setUpUpdater()
                    await projectBoardRef.subscribeProjectHub()
                    
                    await projectBoardRef.createProjectSource()
                }
            }
            
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    await projectBoardRef.setUpUpdater()
                    await projectBoardRef.subscribeProjectHub()
                    
                    await projectBoardRef.createProjectSource()
                }
            }
            
            
            try await #require(projectBoardRef.projects.count == 2)
        
            // when
            await profileBoardRef.signOut()
            
            // then
            for project in await projectBoardRef.projects {
                await #expect(project.isExist == false)
            }
        }
        @Test func deleteProjectUpdater() async throws {
            // given
            let projectBoard = try #require(await budClientRef.projectBoard)
            let projectBoardRef = try #require(await projectBoard.ref)
            
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    await projectBoardRef.setUpUpdater()
                    await projectBoardRef.subscribeProjectHub()
                    
                    await projectBoardRef.createProjectSource()
                }
            }
            
            try await #require(projectBoardRef.projects.count == 1)
            
            let projectRef = await projectBoardRef.projects.first!.ref!
            await projectRef.setUp()
            
            let updater = try #require(await projectRef.updater)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(updater.isExist == false)
        }
        @Test func deleteSystemBoard() async throws {
            // given
            let projectRef = try await getProject(budClientRef)
            await projectRef.setUp()
            
            let systemBoard = try #require(await projectRef.systemBoard)
            try await #require(systemBoard.isExist == true)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(systemBoard.isExist == false)
        }
        @Test func deleteFlowBoard() async throws {
            // given
            let projectRef = try await getProject(budClientRef)
            await projectRef.setUp()
            
            let flowBoard = try #require(await projectRef.flowBoard)
            try await #require(flowBoard.isExist == true)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(flowBoard.isExist == false)
        }
        
        @Test func deleteProfileBoard() async throws {
            // given
            let profileBoard = try #require(await budClientRef.profileBoard)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(budClientRef.profileBoard == nil)
            await #expect(profileBoard.isExist == false)
        }
        @Test func deleteCommunity() async throws {
            // given
            let community = try #require(await budClientRef.community)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(community.isExist == false
            )
        }
        
        @Test func setNilUserIdInBudCache() async throws {
            // given
            let budCacheLink = budClientRef.budCacheLink
            try await #require(budCacheLink.getUser() != nil)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(budCacheLink.getUser() == nil)
        }
    }
}


// MARK: Helphers
private func getProfileBoard(_ budClientRef: BudClient) async throws -> ProfileBoard {
    await signIn(budClientRef)
    
    let profileBoard = await budClientRef.profileBoard!
    return await profileBoard.ref!
}

private func getProject(_ budClientRef: BudClient) async throws -> Project {
    let projectBoard = try #require(await budClientRef.projectBoard)
    let projectBoardRef = try #require(await projectBoard.ref)
    
    // createProject
    await withCheckedContinuation { con in
        Task {
            await projectBoardRef.setCallback {
                con.resume()
            }
            await projectBoardRef.setUpUpdater()
            await projectBoardRef.subscribeProjectHub()
            
            await projectBoardRef.createProjectSource()
        }
    }
    
    await projectBoardRef.unsubscribeProjectHub()
    await projectBoardRef.setCallback { }
    await projectBoardRef.subscribeProjectHub()
    
    try await #require(projectBoardRef.projects.count == 1)
    
    
    let project = try await #require(projectBoardRef.projects.first)
    let projectRef = try #require(await project.ref)
    return projectRef
}
