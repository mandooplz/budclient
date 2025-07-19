//
//  ObjectModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values
import BudServer
import Collections

private let logger = BudLogger("ObjectModelUpdater")


// MARK: Object
extension ObjectModel {
    @MainActor @Observable
    final class Updater: UpdaterInterface {
        // MARK: core
        init(owner: ObjectModel.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let id = UUID()
        nonisolated let owner: ObjectModel.ID
        
        var queue: Deque<ObjectSourceEvent> = []
        var issue: (any IssueRepresentable)?
        
        
        // MARK: action
        func update(mutateHook: Hook? = nil) async {
            
        }
        
        
        // MARK: value
        typealias Event = ObjectSourceEvent
    }
}

