//
//  RegisterRequestTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Testing
import BudServerLink


// MARK: Tags
extension Tag {
    @Tag static var real: Self
}


// MARK: Tests
@Suite("RegisterRequest")
struct RegisterRequestTests {
    struct Submit {
        @Test func createAccount()  {
           
        }
        
        @Test func insertAccount() {
            
        }
    }
}
