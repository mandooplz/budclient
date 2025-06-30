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
        init() async throws {
            self.budClientRef = await BudClient()
            self.profileBoardRef = try await getProfileBoard(budClientRef)
        }
        
        @Test func whenProfileBoardIsDeletedBeforeCapture() async throws {
            // given
            try await #require(budClientRef.profileBoard?.isExist == true)
            
            let budCacheLink = budClientRef.budCacheLink
            try await #require(budCacheLink.getUserId() != nil)
            
            // when
            await profileBoardRef.signOut {
                await profileBoardRef.delete()
            } mutateHook: {
                
            }

            // then
            try await #require(budClientRef.profileBoard?.isExist == false)
            await #expect(budCacheLink.getUserId() != nil)
        }
        @Test func whenProfileBoardIsDeletedBeforeMutate() async throws {
            // given
            try await #require(budClientRef.profileBoard?.isExist == true)
            
            let budCacheLink = budClientRef.budCacheLink
            try await #require(budCacheLink.getUserId() != nil)
            
            // when
            await profileBoardRef.signOut {
                
            } mutateHook: {
                await profileBoardRef.delete()
            }

            // then
            try await #require(budClientRef.profileBoard?.isExist == false)
            
            await #expect(budClientRef.isUserSignedIn == true)
        }
        
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
        @Test func deleteProjectsInProjectBoard() async throws {
            // given
            let projectBoard = try #require(await budClientRef.projectBoard)
            let projectBoardRef = try #require(await projectBoard.ref)
            let projects = await projectBoardRef.projects
            
            // when
            await profileBoardRef.signOut()
            
            // then
            for project in projects {
                await #expect(project.isExist == false)
            }
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
            try await #require(budCacheLink.getUserId() != nil)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(budCacheLink.getUserId() == nil)
        }
    }
}


// MARK: Helphers
private func getProfileBoard(_ budClientRef: BudClient) async throws -> ProfileBoard {
    await signIn(budClientRef)
    
    let profileBoard = await budClientRef.profileBoard!
    return await profileBoard.ref!
}
