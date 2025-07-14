//
//  SystemModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation
import Values
import Collections
import BudServer


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
            case .added:
                fatalError()
            case .modified:
                fatalError()
            case .removed:
                fatalError()
            }
        }
    }
}
