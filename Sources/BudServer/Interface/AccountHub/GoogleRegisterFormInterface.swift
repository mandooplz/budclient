//
//  GoogleRegisterFormInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values
import CryptoKit


// MARK: Interface
package protocol GoogleRegisterFormInterface: Sendable {
    associatedtype ID: GoogleRegisterFormIdentity where ID.Object == Self
    
    // MARK: state
    func setToken(_ token: GoogleToken) async;
    
    // MARK: action
    func submit() async throws
    func remove() async
}

package protocol GoogleRegisterFormIdentity: Sendable, Hashable {
    associatedtype Object: GoogleRegisterFormInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}


// MARK: value
package struct GoogleToken: Sendable, Hashable {
    package let idToken: String
    package let accessToken: String
    
    package init(idToken: String, accessToken: String) {
        self.idToken = idToken
        self.accessToken = accessToken
    }
    
    package func getValue() -> String {
        let combined = idToken + ":" + accessToken
        
        // SHA256 해시를 사용한 결정론적 user id 생성
        let data = combined.data(using: .utf8)!
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    package static func random() -> GoogleToken {
        return .init(idToken: Token.random().value,
                     accessToken: Token.random().value)
    }
}
