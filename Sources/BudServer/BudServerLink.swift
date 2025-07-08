//
//  BudServer.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Values
import BudServerMock
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore


// MARK: Link
public struct BudServerLink: Sendable {
    // MARK: core
    private let mode: SystemMode
    private let budSeverMockRef: BudServerMock!
    
    package init(plistPath: String) async throws(Error) {
        self.mode = .real
        self.budSeverMockRef = nil
        
        if FirebaseApp.app() != nil { return }
        
        
        guard let options = FirebaseOptions(contentsOfFile: plistPath) else {
            throw Error.plistPathIsWrong
        }
        await MainActor.run {
            FirebaseApp.configure(options: options)
        }
    }
    package init(budServerMockRef: BudServerMock) async {
        self.mode = .test
        self.budSeverMockRef = budServerMockRef
        
        await budServerMockRef.setUp()
    }
    
    
    // MARK: state
    public func getGoogleClientId() -> String? {
        FirebaseApp.app()?.options.clientID
    }
    
    package func getAccountHub() async -> AccountHubLink {
        switch mode {
        case .test:
            return await AccountHubLink(mode: .test(budSeverMockRef.accountHubRef!))
        case .real:
            return AccountHubLink(mode: .real)
        }
    }
    package func getProjectHub() async -> ProjectHubLink {
        switch mode {
        case .test:
            return await ProjectHubLink(mode: .test(budSeverMockRef.projectHubRef!))
        case .real:
            return ProjectHubLink(mode: .real)
        }
    }
    
    
    // MARK: value
    package enum Error: String, Swift.Error {
        case plistPathIsWrong
    }
}

