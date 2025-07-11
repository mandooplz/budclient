//
//  Handler.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//


// MARK: Handler
package struct Handler<Event>: Sendable where Event: Sendable {
    package let routine: @Sendable (Event, WorkFlow.ID) -> Void
    
    package func execute(_ event: Event, workflow: WorkFlow.ID = WorkFlow.id) {
        self.routine(event, workflow)
    }
    
    package init(_ routine: @Sendable @escaping (Event, WorkFlow.ID) -> Void) {
        self.routine = routine
    }
}
