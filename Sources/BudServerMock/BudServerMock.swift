//
//  BudServerMock.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation
import Values


// MARK: Object
@Server
package final class BudServerMock {
    // MARK: core
    package nonisolated init() { }
    
    
    // MARK: state
    @Server package var accountHubRef: AccountHubMock?
    @Server package var projectHubRef: ProjectHubMock?
    
    
    // MARK: action
    @Server package func setUp() {
        guard accountHubRef == nil || projectHubRef == nil else { return }
                
        self.accountHubRef = AccountHubMock()
        self.projectHubRef = ProjectHubMock()
    }
}
