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
    // 이 루틴은 어딘가에 존재하는 BudServer의 링크를 생성하는 루틴
    public init(mode: SystemMode = .real) throws {
        if mode == .real {
            guard let filePath = Bundle.module.path(forResource: "GoogleService-Info",
                                                    ofType: "plist"),
                  let options = FirebaseOptions(contentsOfFile: filePath) else {
                return
            }
            
            FirebaseApp.configure(options: options)
        }
    }
}

