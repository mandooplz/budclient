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
    package init(mode: Mode) throws(Error) {
        self.mode = mode
        
        if case .real(let plistPath) = mode {
            if FirebaseApp.app() != nil { return }
            
            guard let options = FirebaseOptions(contentsOfFile: plistPath) else {
                throw Error.plistPathIsWrong
            }
            FirebaseApp.configure(options: options)
        }
    }
    
    
    // MARK: state
    public func getGoogleClientId() -> String? {
        FirebaseApp.app()?.options.clientID
    }
    package func getAccountHub() -> AccountHubLink {
        AccountHubLink(mode: mode.toSystemMode)
    }
    package func getProjectHub() -> ProjectHubLink {
        ProjectHubLink(mode: mode.toSystemMode)
    }
    
    
    // MARK: value
    package enum Error: String, Swift.Error {
        case plistPathIsWrong
    }
    package enum Mode: Sendable {
        case test
        case real(plistPath: String)
        
        var toSystemMode: SystemMode {
            switch self {
            case .test:
                return .test
            case .real:
                return .real
            }
        }
    }
}
