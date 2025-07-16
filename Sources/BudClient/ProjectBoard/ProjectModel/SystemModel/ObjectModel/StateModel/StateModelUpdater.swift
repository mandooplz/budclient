//
//  StateModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values


// MARK: Object
extension StateModel {
    @MainActor @Observable
    final class Updater: Sendable {
        // MARK: core
        init(owner: StateModel.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let id = UUID()
        nonisolated let owner: StateModel.ID
        
        
        // MARK: action
        func update(mutateHook: Hook? = nil) async { }
    }
}
