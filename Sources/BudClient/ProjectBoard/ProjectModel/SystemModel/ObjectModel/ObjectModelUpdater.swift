//
//  ObjectModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values

private let logger = WorkFlow.getLogger(for: "ObjectModel.Updater")


// MARK: Object
extension ObjectModel {
    @MainActor @Observable
    final class Updater: Sendable {
        // MARK: core
        init(owner: ObjectModel.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let id = UUID()
        nonisolated let owner: ObjectModel.ID
        
        
        // MARK: action
        func update(mutateHook: Hook? = nil) async { }
        
        
        // MARK: value
    }
}

