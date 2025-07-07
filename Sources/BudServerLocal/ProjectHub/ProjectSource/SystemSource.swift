//
//  SystemSource.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import FirebaseFirestore
import Values


// MARK: Object
@MainActor
package final class SystemSource: Sendable {
    // MARK: core
    
    
    // MARK: state
    
    
    // MARK: action
    
    
    // MARK: value
    package struct Data: Hashable, Codable {
        @DocumentID var id: String?
        var name: String
        var location: Location
    }
    package enum State: Sendable, Hashable {
        static let name = "name"
        static let location = "location"
    }
}

