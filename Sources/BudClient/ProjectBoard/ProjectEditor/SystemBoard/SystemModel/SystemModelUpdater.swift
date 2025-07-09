//
//  SystemModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation
import Values


// MARK: Object
@MainActor @Observable
final class SystemModelUpdater: Sendable {
    // MARK: core
    
    
    // MARK: state
    nonisolated let id = ID()
    
    
    // MARK: action
    
    
    // MARK: value
    @MainActor
    struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            false
        }
        var ref: SystemModelUpdater? {
            nil
        }
    }
}


// MARK: ObjectManager
@MainActor @Observable
fileprivate final class SystemModelUpdaterManager: Sendable {
    // MARK: state
}
