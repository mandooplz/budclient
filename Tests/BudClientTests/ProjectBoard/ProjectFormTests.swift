//
//  ProjectFormTests.swift
//  BudClient
//
//  Created by 김민우 on 7/1/25.
//
import Testing
import Tools
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("ProjectForm")
struct ProjectFormTests {
    struct Submit {
        let budClientRef: BudClient
        let projectFormRef: ProjectForm
        init() async {
            self.budClientRef = BudClient()
            self.projectFormRef = getProjectForm(budClientRef)
        }
    }
}
