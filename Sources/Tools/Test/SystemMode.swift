//
//  SystemMode.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//


// MARK: SystemMode
// Mode는 어떤 값인가. 
@frozen
public enum SystemMode: Sendable, Hashable, Codable {
    case test
    case real
}

