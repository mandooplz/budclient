//
//  ProjectID.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation


// MARK: ProjectID
public struct ProjectID: Identity, Codable {
    public let value: UUID
}
