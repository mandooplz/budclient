//
//  ProjectModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/16/25.
//
import Foundation
import Values
import BudServer

private let logger = WorkFlow.getLogger(for: "ProjectModel,pdate")


// MARK: Object
extension ProjectModel {
    @MainActor @Observable
    final class Updater: Sendable, Identifiable {
        // MARK: core
        init(parent: ProjectModel.ID) {
            self.parent = parent
        }
        
        
        // MARK: state
        nonisolated let id = UUID()
        nonisolated let parent: ProjectModel.ID
        
        // 어떤 이벤트를 받아야 하는가.
        
        
        // MARK: action
        func update() {
            
        }
        
        
        // MARK: value
        enum Event: Sendable, Hashable {
            
        }
    }
}
