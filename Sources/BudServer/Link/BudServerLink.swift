//
//  BudServer.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore


// MARK: Link
public struct BudServerLink: Sendable {
    // MARK: core
    private let mode: Mode
    package init(mode: Mode) async throws(Error) {
        self.mode = mode
        
        if case .real(let plistPath) = mode {
            if FirebaseApp.app() != nil { return }
            
            
            guard let options = FirebaseOptions(contentsOfFile: plistPath) else {
                throw Error.plistPathIsWrong
            }
            await MainActor.run {
                FirebaseApp.configure(options: options)
            }
        }
    }
    
    
    // MARK: state
    public func getGoogleClientId() -> String? {
        FirebaseApp.app()?.options.clientID
    }
    
    package func getAccountHub() async -> AccountHubLink {
        await AccountHubLink(mode: mode.forAccountHub)
    }
    package func getProjectHub() async -> ProjectHubLink {
        await ProjectHubLink(mode: mode.forProjectHub)
    }
    
    
    
    // MARK: value
    package enum Error: String, Swift.Error {
        case plistPathIsWrong
    }
    package enum Mode: Sendable {
        case test(BudServerMock)
        case real(plistPath: String)
        
        @Server
        var forAccountHub: AccountHubLink.Mode {
            switch self {
            case .test(let budServerMock):
                .test(budServerMock.accountHubRef!)
            case .real:
                    .real
            }
        }
        
        @Server
        var forProjectHub: ProjectHubLink.Mode {
            switch self {
            case .test(let budServerMock):
                    .test(budServerMock.projectHubRef!)
            case .real:
                    .real
            }
        }
    }
}
