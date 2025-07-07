//
//  SystemSourceLink.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values


// MARK: Link
package struct SystemSourceLink: Sendable {
    // MARK: core
    private let mode: SystemMode
    private let object: SystemSourceID
    package init(mode: SystemMode, object: SystemSourceID) {
        self.mode = mode
        self.object = object
    }
    
    
    // MARK: 
}
