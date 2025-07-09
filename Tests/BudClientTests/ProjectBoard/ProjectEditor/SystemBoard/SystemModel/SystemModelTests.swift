//
//  SystemModelTests.swift
//  BudClient
//
//  Created by 김민우 on 7/8/25.
//
import Foundation
import Testing
import Values
@testable import BudClient


// MARK: Tests
@Suite("SystemModel", .timeLimit(.minutes(1)))
struct SystemModelTests {
    struct SetUp {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async {
            self.budClientRef = await BudClient()
            self.systemModelRef = await getSystemModel(budClientRef)
        }
        
        @Test func createSystemModelUpdater() {
            Issue.record("미구현")
        }
        @Test func whenAlreadySetUp() {
            Issue.record("미구현")
        }
    }
    
    struct Subscribe {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async {
            self.budClientRef = await BudClient()
            self.systemModelRef = await getSystemModelWithSetUp(budClientRef)
        }
    }
    
    struct Unsubscribe {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async {
            self.budClientRef = await BudClient()
            self.systemModelRef = await getSystemModelWithSetUp(budClientRef)
        }
    }

}
