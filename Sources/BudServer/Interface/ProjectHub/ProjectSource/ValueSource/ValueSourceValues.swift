//
//  ValueSourceValues.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation

// MARK: ValueData
// 상태를 표현할 수 있는 값의 종류를 표현하는 값
// ValueData("Int")
// ValueData("String")
// ValueData("Float")
// ValueData("Double")
// ValueData("")
public struct ValueData: Sendable, Hashable {
    public let name: String
}


// MARK: ValueSourceDiff
package struct ValueSourceDiff: Sendable {
    
}

