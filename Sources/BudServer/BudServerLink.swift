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
    
    public init(mode: SystemMode = .real,
                plistPath: String = "") throws(Error) {
        self.mode = mode
        
        if mode == .real {
            if FirebaseApp.app() != nil { return }
            
            guard let options = FirebaseOptions(contentsOfFile: plistPath) else {
                throw .plistPathIsWrong
            }
            FirebaseApp.configure(options: options)
        }
    }
    
    // MARK: state
    public func getAccountHub() -> AccountHubLink {
        AccountHubLink(mode: self.mode)
    }
    public enum Error: String, Swift.Error {
        case plistPathIsWrong
    }
}
