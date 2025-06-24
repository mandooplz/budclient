//
//  BudServer.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools
import FirebaseCore


// MARK: Link
public struct BudServerLink: Sendable {
    // MARK: core
    private let mode: SystemMode
    public init(mode: SystemMode = .real) {
        self.mode = mode
        
        if mode == .real {
            if FirebaseApp.app() != nil { return }
            
            let filePath = Bundle.module.path(forResource: "GoogleService-Info", ofType: "plist")!
            let options = FirebaseOptions(contentsOfFile: filePath)!
            
            FirebaseApp.configure(options: options)
        }
    }
    
    // MARK: state
    public func getAccountHub() -> AccountHubLink {
        AccountHubLink(mode: self.mode)
    }
}
