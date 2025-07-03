//
//  BudServerMock.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor
package final class BudServerMock: Sendable {
    // MARK: core
    package static let shared = BudServerMock()
    package init() { }
    
    
    // MARK: state
    @Server var accountHubRef: AccountHubMock?
    @Server var projectHubRef: ProjectHubMock?
    
    
    // MARK: action
    @Server package func setUp() {
        self.accountHubRef = AccountHubMock()
        self.projectHubRef = ProjectHubMock()
    }
}
