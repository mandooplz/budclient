//
//  SystemBoardUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/8/25.
//
import Foundation
import Values
import Collections
import BudServer
import os


// MARK: Object
@MainActor @Observable
final class SystemBoardUpdater: Sendable, Debuggable, UpdaterInterface {
    // MARK: core
    init(config: Config<SystemBoard.ID>) {
        self.config = config
    }
    
    // MARK: state
    nonisolated let config: Config<SystemBoard.ID>
    
    var queue: Deque<ProjectSourceEvent> = []
    
    var issue: (any Issuable)?
    
    
    // MARK: action
    func update() async {
        // mutate
        let config = self.config
        let systemBoardRef = config.parent.ref!
        
        while queue.isEmpty == false {
            let event = queue.removeFirst()
            switch event {
            case .added(let diff):
                if systemBoardRef.isExist(diff.target) {
                    setIssue(Error.alreadyAdded); return
                }
                
                let systemModelRef = SystemModel(config: config,
                                                 target: diff.target,
                                                 source: diff.id)
                systemBoardRef.models[diff.location] = systemModelRef.id
            case .removed(let diff):
                guard systemBoardRef.isExist(diff.target) else {
                    setIssue(Error.alreadyRemoved); return
                }
                
                let systemModel = systemBoardRef.models.values
                    .first { $0.ref?.target == diff.target }
                
                systemModel!.ref?.delete()
                systemBoardRef.models[diff.location] = nil
            case .modified(let diff):
                guard let systemModel = systemBoardRef.getSystemModel(diff.target) else{
                    setIssue(Error.alreadyRemoved); return
                }
                let systemModelRef = systemModel.ref!
                
                systemModelRef.name = diff.name
                systemModelRef.location = diff.location
            }
        }
    }
    
    
    // MARK: value
    @MainActor
    struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            SystemBoardUpdaterManager.container[self] != nil
        }
        var ref: SystemBoardUpdater? {
            SystemBoardUpdaterManager.container[self]
        }
    }
    enum Error: String, Swift.Error {
        case updaterIsDeleted
        case alreadyAdded, alreadyRemoved
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class SystemBoardUpdaterManager: Sendable {
    // MARK: state
    fileprivate static var container: [SystemBoardUpdater.ID: SystemBoardUpdater] = [:]
}
