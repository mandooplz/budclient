//
//  CreateGoogleForm.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation


// MARK: CreateGoogleForm
public struct CreateGoogleForm: Ticket {
    let value: UUID
    
    public init(value: UUID = UUID()) {
        self.value = value
    }
}
