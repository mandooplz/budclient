//
//  SystemUpdaterTests.swift
//  BudClient
//
//  Created by 김민우 on 7/8/25.
//
import Foundation
import Testing
@testable import BudClient


// MARK: Tests
@Suite("SystemUpdater")
struct SystemUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let updaterRef: SystemUpdater
        init() async {
            self.budClientRef = await BudClient()
            self.updaterRef = await getUpdater(budClientRef)
        }
        
        @Test func whenUpdaterIsDeletedBeforeMutate() async throws {
            // given
            
            // when
            
            // then
        }
    }
}



// MARK: Helpher
private func getUpdater(_ budClientRef: BudClient) async -> SystemUpdater {
    let systemBoardRef = await createAndGetSystemBoard(budClientRef)
    
    await systemBoardRef.setUp()
    
    return await systemBoardRef.updater!.ref!
}
