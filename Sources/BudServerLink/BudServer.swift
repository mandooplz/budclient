//
//  BudServerLink.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools
import FirebaseCore


// MARK: Link
public struct BudServer: Sendable {
    // MARK: link
    private nonisolated let mode: SystemMode
    public init(mode: SystemMode = .real) throws {
        self.mode = mode
        if mode == .real {
            if FirebaseApp.app() != nil {
                return
            }
            guard let filePath = Bundle.module.path(forResource: "GoogleService-Info",
                                                    ofType: "plist"),
                  let options = FirebaseOptions(contentsOfFile: filePath) else {
                return
            }
            
            FirebaseApp.configure(options: options)
        }
    }
}
