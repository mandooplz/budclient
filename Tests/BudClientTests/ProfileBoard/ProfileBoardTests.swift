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
@Suite("ProfileBoard", .timeLimit(.minutes(1)))
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
            
            let budCacheRef = try #require(await profileBoardRef.config.budCache.ref)
            
            try await #require(budCacheRef.getUser() != nil)
            
            // when
            await profileBoardRef.signOut {
                await profileBoardRef.delete()
            } mutateHook: {
                
            }

            // then
            let issue = try #require(await profileBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "profileBoardIsDeleted")
            
            try await #require(budClientRef.profileBoard?.isExist == false)
            await #expect(budCacheRef.getUser() != nil)
        }
        @Test func whenProfileBoardIsDeletedBeforeMutate() async throws {
            // given
            try await #require(budClientRef.profileBoard?.isExist == true)
            
            let budCacheRef = try #require(await profileBoardRef.config.budCache.ref)
            try await #require(budCacheRef.getUser() != nil)
            
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
        @Test func deleteProjectEditors() async throws {
            // given
            let projectBoard = try #require(await budClientRef.projectBoard)
            let projectBoardRef = try #require(await projectBoard.ref)
            
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    await projectBoardRef.subscribe()
                    
                    await projectBoardRef.createNewProject()
                }
            }
            
            await projectBoardRef.unsubscribe()
            
            
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    await projectBoardRef.subscribe()
                    
                    await projectBoardRef.createNewProject()
                }
            }
            
            
            try await #require(projectBoardRef.editors.count == 2)
        
            // when
            await profileBoardRef.signOut()
            
            // then
            for projectEditor in await projectBoardRef.editors {
                await #expect(projectEditor.isExist == false)
            }
        }
        
        @Test func deleteSystemBoard() async throws {
            // given
            let projectEditorRef = await getProjectEditor(budClientRef)
            await projectEditorRef.setUp()
            
            let systemBoard = try #require(await projectEditorRef.systemBoard)
            try await #require(systemBoard.isExist == true)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(systemBoard.isExist == false)
        }
        @Test func deleteSystemModel() async throws {
            // given
            let budClientRef = await BudClient()
            let systemModelRef = await getSystemModel(budClientRef)
            
            let profileBoardRef = try #require(await budClientRef.profileBoard?.ref)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(systemModelRef.id.isExist == false)
        }
        
        @Test func deleteFlowBoard() async throws {
            // given
            let projectEditorRef = await getProjectEditor(budClientRef)
            await projectEditorRef.setUp()
            
            let flowBoard = try #require(await projectEditorRef.flowBoard)
            try await #require(flowBoard.isExist == true)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(flowBoard.isExist == false)
        }
        
        @Test func deleteValueBoard() async throws {
            // given
            let projectEditorRef = await getProjectEditor(budClientRef)
            await projectEditorRef.setUp()
            
            let valueBoard = try #require(await projectEditorRef.valueBoard)
            try await #require(valueBoard.isExist == true)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(valueBoard.isExist == false)
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
            let budCacheRef = try #require(await profileBoardRef.config.budCache.ref)
            try await #require(budCacheRef.getUser() != nil)
            
            // when
            await profileBoardRef.signOut()
            
            // then
            await #expect(budCacheRef.getUser() == nil)
        }
    }
}


// MARK: Helphers
private func getProfileBoard(_ budClientRef: BudClient) async throws -> ProfileBoard {
    await signIn(budClientRef)
    
    let profileBoard = await budClientRef.profileBoard!
    return await profileBoard.ref!
}
