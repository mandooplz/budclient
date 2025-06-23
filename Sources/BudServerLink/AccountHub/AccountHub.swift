//
//  AccountHub.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation


// MARK: Object
@MainActor
public final class AccountHub: Sendable {
    // MARK: state
    public static var accounts: Set<Account.ID> = []
    public static func isExist(email: String, password: String) -> Bool {
        // capture
        let accounts = self.accounts
        
        // compute
        let isExist = accounts.lazy
            .compactMap { AccountManager.get($0) }
            .contains { $0.email == email && $0.password == password }
        return isExist
    }
    
}
