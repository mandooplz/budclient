//
//  SystemModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation
import Values
import Collections


// MARK: Object
@MainActor @Observable
final class SystemModelUpdater: Sendable, Debuggable, UpdaterInterface {
    // MARK: core
    init() { }
    
    
    // MARK: state
    var issue: (any Issuable)?
    var queue: Deque<SystemSourceEvent> = []
    
    
    // MARK: action
    func update() {
        // mutate
        while queue.isEmpty == false {
            let event = queue.removeFirst()
            
            switch event {
            case .root(let rootEvent):
                switch rootEvent {
                case .created(let rootSource, let target):
                    fatalError()
                case .modified(let diff):
                    fatalError()
                case .deleted(let rootSource):
                    fatalError()
                }
            case .object(let objectEvent):
                switch objectEvent {
                case .added(let objectSource, let target):
                    fatalError()
                case .modified(let diff):
                    fatalError()
                case .removed(let target):
                    fatalError()
                }
            }
        }
    }
}
