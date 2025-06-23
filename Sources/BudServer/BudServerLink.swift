//
//  BudServerLink.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import FirebaseCore


// MARK: Link
public struct BudServerLink: Sendable {
    public init() throws {
        if let filePath = Bundle.module.path(forResource: "GoogleService-Info", ofType: "plist") {
            print("✅ plist 파일 경로: \(filePath)")
            
            let options = FirebaseOptions(contentsOfFile: filePath)!
            FirebaseApp.configure(options: options)
            print("Firebase 수동 구성 완료")
        } else {
            print("❌ plist 파일을 찾을 수 없습니다.")
        }
    }
}

